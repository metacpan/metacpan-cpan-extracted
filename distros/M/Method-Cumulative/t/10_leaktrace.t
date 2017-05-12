#!perl -w

use strict;
use Test::More tests => 4;
use Test::LeakTrace;

BEGIN{ require MRO::Compat if $] < 5.010 }

{
	package A;
	use parent qw(Method::Cumulative);

	sub new{ bless {}, shift }

	sub foo{
		my($self, $x) = @_;
	}

	sub bar{
		my($self, $x) = @_;
	}

	package B;
	use parent -norequire => qw(A);

	sub foo :CUMULATIVE{
		my($self, $x) = @_;
	}
	sub bar :CUMULATIVE(BASE FIRST){
		my($self, $x) = @_;
	}

	package C;
	use parent -norequire => qw(A);

	sub foo :CUMULATIVE{
		my($self, $x) = @_;
	}
	sub bar :CUMULATIVE(BASE FIRST){
		my($self, $x) = @_;
	}

	package D;
	use parent -norequire => qw(C B);
	use mro 'c3';

	sub foo :CUMULATIVE{
		my($self, $x) = @_;
	}
	sub bar :CUMULATIVE(BASE FIRST){
		my($self, $x) = @_;
	}
}


no_leaks_ok{
	B->foo();
};

no_leaks_ok{
	B->bar();
};

no_leaks_ok{
	D->foo();
};

no_leaks_ok{
	D->bar();
};
