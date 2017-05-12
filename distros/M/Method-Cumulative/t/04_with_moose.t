#!perl -w

use strict;
use constant HAS_MOOSE => eval{ require Moose };
use Test::More HAS_MOOSE ? (tests => 2) : (skip_all => 'tests with Moose');


my @tags;
{
	package A;
	use Moose;

	sub foo{
		push @tags, 'A';
	}
	sub bar{
		push @tags, 'A';
	}

	package B;
	use Moose;
	use parent qw(Method::Cumulative);

	extends qw(A);
	sub foo :CUMULATIVE{
		push @tags, 'B';
	}
	sub bar :CUMULATIVE(BASE FIRST){
		push @tags, 'B';
	}

	package C;
	use Moose;
	use parent qw(Method::Cumulative);

	extends qw(A);

	sub foo :CUMULATIVE{
		push @tags, 'C';
	}
	sub bar :CUMULATIVE(BASE FIRST){
		push @tags, 'C';
	}

	package D;
	use Moose;
	use parent qw(Method::Cumulative);
	use mro 'c3';

	extends qw(C B);

	sub foo :CUMULATIVE{
		push @tags, 'D';
	}
	sub bar :CUMULATIVE(BASE FIRST){
		push @tags, 'D';
	}
}

D->foo;
is_deeply \@tags, [qw(D C B A)];

@tags = ();
D->bar;
is_deeply \@tags, [qw(A B C D)];
