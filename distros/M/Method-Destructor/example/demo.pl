#!perl -w
use strict;

BEGIN{
	package
		Base;

	use strict;
	use Method::Destructor -optional;

	sub new{
		bless {}, shift;
	}

	sub DEMOLISH{
		print __PACKAGE__, "::DEMOLISH\n";
	}

	package
		Derived;
	use Method::Destructor;
	use parent -norequire => qw(Base);

	sub DEMOLISH{
		print __PACKAGE__, "::DEMOLISH\n";
	}
}

print "# Both Derived::DEMOLISH and Base::DEMOLISH are called.\n";
Derived->new;

print "# Derived::DEMOLISH is called, but Base::DMEOLISH is omitted.\n";
our $bar = Derived->new();

