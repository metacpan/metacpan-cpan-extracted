#!perl -w

use strict;
use Test::More tests => 24;

use MRO::Compat;

my @tags;

BEGIN{
	package A;
	use Method::Destructor;

	sub new{ bless {}, shift }

	sub DEMOLISH{
		::is scalar(@_), 1;
		::isa_ok $_[0], __PACKAGE__;

		push @tags, __PACKAGE__;
	}

	package B;
	use parent -norequire => qw(A);

	sub DEMOLISH{
		push @tags, __PACKAGE__;
	}

	package C;
	use parent -norequire => qw(A);

	sub DEMOLISH{
		push @tags, __PACKAGE__;
	}

	package D;
	use mro 'c3';
	use parent -norequire => qw(C B);

	sub DEMOLISH{
		push @tags, __PACKAGE__;
	}
}

for(1 .. 2){
	@tags = ();
	A->new();
	is_deeply \@tags, [qw(A)], "A/$_" or diag "[@tags]";

	@tags = ();
	B->new();
	is_deeply \@tags, [qw(B A)], "B/$_" or diag "[@tags]";

	@tags = ();
	C->new();
	is_deeply \@tags, [qw(C A)], "C/$_" or diag "[@tags]";

	@tags = ();
	D->new();
	is_deeply \@tags, [qw(D C B A)], "D/$_" or diag "[@tags]";
}
