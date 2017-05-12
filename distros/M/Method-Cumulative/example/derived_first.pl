#!perl -w
use strict;

{
	package A;
	use Mouse;

	sub foo{
		print "A";
	}

	package B;
	use Mouse;
	use parent qw(Method::Cumulative);

	extends qw(A);

	sub foo :CUMULATIVE{
		print "B";
	}

	package C;
	use Mouse;
	use parent qw(Method::Cumulative);

	extends qw(A);

	sub foo :CUMULATIVE{
		print "C";
	}

	package D;
	use Mouse;
	use parent qw(Method::Cumulative);
	use mro 'c3';

	extends qw(C B);

	sub foo :CUMULATIVE{
		print "D";
	}
}
D->foo(); # => DCBA
print "\n";
