#!perl -w

use strict;

use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ? (tests => 3) : (skip_all => 'require Test::LeakTrace');

use Test::LeakTrace;
use MRO::Compat;
{
	package Foo;
	use Method::Destructor;

	sub new{
		my($class, %args) = @_;
		return bless \%args, $class;
	}

	sub DEMOLISH{
		$_[0]->{demolish}++;
	}

	package Bar;
	use parent -norequire => qw(Foo);

	sub DEMOLISH{
		$_[0]->{demolish}++;
	}
}

no_leaks_ok{

	Foo->new();

} 'demolish (single)';

no_leaks_ok{

	Bar->new();

} 'demolish (culumative)';

no_leaks_ok{
	Bar->new();

	mro::method_changed_in('Foo');
} 'with method_changed_in("Foo")';
