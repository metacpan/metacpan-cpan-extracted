#!perl -w

use strict;
use Test::More tests => 18;

BEGIN{ require MRO::Compat if $] < 5.010 }

{
	package A;
	use parent qw(Method::Cumulative);

	sub new{ bless {}, shift }

	sub foo{
		return 'A';
	}

	sub bar{
		return 'A';
	}

	sub baz{
		return(1 .. 3);
	}

	package B;
	use parent -norequire => qw(A);

	sub foo :CUMULATIVE{
		return;
	}
	sub bar :CUMULATIVE(BASE FIRST){
		return;
	}

	sub baz :CUMULATIVE{
		return;
	}

	package C;
	use parent -norequire => qw(A);

	sub foo :CUMULATIVE{
		return 'C';
	}
	sub bar :CUMULATIVE(BASE FIRST){
		return 'C';
	}

	sub baz :CUMULATIVE{
		return 42;
	}

	package D;
	use parent -norequire => qw(C B);
	use mro 'c3';

	sub foo :CUMULATIVE{
		return;
	}
	sub bar :CUMULATIVE(BASE FIRST){
		return;
	}

	sub baz :CUMULATIVE{
		return;
	}
}

for(1 .. 2){
	my $b = B->new();
	my $c = C->new();
	my $d = D->new();

	is $b->foo, 'A';
	is $b->bar, 'A';

	is $c->foo, 'C';
	is $c->bar, 'A';

	is $d->foo, 'C';
	is $d->bar, 'A';
}

for(1 .. 2){
	is_deeply [B->baz], [1..3];
	is_deeply [C->baz], [42];
	is_deeply [D->baz], [42];
}