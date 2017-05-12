package Memoize::Memcached::Attribute::Test;

use base qw(Test::Class);

use strict;
use Test::More;
use Test::Deep;

use Mock::Cache::Memcached;

our %called;

{
	package Memoize::Memcached::Attribute::Test::Class;

	use Memoize::Memcached::Attribute (-client => Mock::Cache::Memcached->new);

	sub new {
		return bless $_[1], $_[0];
	}

	sub expires :CacheMemoize(1) {
		$Memoize::Memcached::Attribute::Test::called{expires}++;
		return 1;
	}

	sub as_unspecified :CacheMemoize(5) {
		$Memoize::Memcached::Attribute::Test::called{as_unspecified}++;
		return 1;
	}

	sub as_function :CacheMemoize(function => 5) {
		$Memoize::Memcached::Attribute::Test::called{as_function}++;
		return 1;
	}

	sub as_method :CacheMemoize(method => 5) {
		$Memoize::Memcached::Attribute::Test::called{as_method}++;
		return 1;
	}

	sub invalidate {
		# so it's coming from this package
		Memoize::Memcached::Attribute::invalidate(@_);
	}
}

sub can_it_blend :Test(startup => 1) {
	require_ok('Memoize::Memcached::Attribute') or BAIL_OUT("Could not compile the module, abandon ship");
}

sub clean_slate :Test(setup) {
	my $self = shift;
	%called = ();
	$Memoize::Memcached::Attribute::MEMCACHE->flush_all;
}

sub reset :Test(2) {
	my $self = shift;

	my $count = $called{as_function} || 0;
	Memoize::Memcached::Attribute::Test::Class::as_function(0..9);
	is($called{as_function}, ++$count, "Function called");

	Memoize::Memcached::Attribute::reset(Mock::Cache::Memcached->new);

	Memoize::Memcached::Attribute::Test::Class::as_function(0..9);
	is($called{as_function}, $count, "Function not called due to being cached");
}

sub as_function :Test(3) {
	my $self = shift;

	my $count = $called{as_function} || 0;
	Memoize::Memcached::Attribute::Test::Class::as_function(0..9);
	is($called{as_function}, ++$count, "Function called");

	Memoize::Memcached::Attribute::Test::Class::as_function(0..9);
	is($called{as_function}, $count, "Function not called due to being cached");

	Memoize::Memcached::Attribute::Test::Class::as_function(1);
	is($called{as_function}, ++$count, "Function called with different parameters not cached");
}

sub as_unspecified :Test(3) {
	my $self = shift;

	my $count = $called{as_unspecified} || 0;
	Memoize::Memcached::Attribute::Test::Class::as_unspecified(0..9);
	is($called{as_unspecified}, ++$count, "Function called");

	Memoize::Memcached::Attribute::Test::Class::as_unspecified(0..9);
	is($called{as_unspecified}, $count, "Function not called due to being cached");

	Memoize::Memcached::Attribute::Test::Class::as_unspecified(1);
	is($called{as_unspecified}, ++$count, "Function called with different parameters not cached");
}

sub invalidate :Test(5) {
	my $self = shift;

	my $count = $called{as_function} || 0;
	Memoize::Memcached::Attribute::Test::Class::as_function(0..9);
	is($called{as_function}, ++$count, "Function called");

	Memoize::Memcached::Attribute::Test::Class::as_function(0..9);
	is($called{as_function}, $count, "Function not called due to being cached");

	Memoize::Memcached::Attribute::Test::Class::invalidate('Memoize::Memcached::Attribute::Test::Class::as_function', 0..9);

	Memoize::Memcached::Attribute::Test::Class::as_function(0..9);
	is($called{as_function}, ++$count, "Function called again not cached due to invalidation");

	Memoize::Memcached::Attribute::Test::Class::as_function(0..9);
	is($called{as_function}, $count, "Function not called due to being cached");

	Memoize::Memcached::Attribute::Test::Class::invalidate('as_function', 0..9);

	Memoize::Memcached::Attribute::Test::Class::as_function(0..9);
	is($called{as_function}, ++$count, "Function called again not cached due to invalidation (without package name)");
}

sub as_method :Test(4) {
	my $self = shift;

	my $count = $called{as_method} || 0;

	my $obj1 = Memoize::Memcached::Attribute::Test::Class->new({ foo => 'bar' });
	my $obj2 = Memoize::Memcached::Attribute::Test::Class->new({ bar => 'foo' });

	$obj1->as_method(0..9);
	is($called{as_method}, ++$count, "Method called");

	$obj1->as_method(0..9);
	is($called{as_method}, $count, "Method called from same object with same parameters returns cache");

	$obj2->as_method(0..9);
	is($called{as_method}, $count, "Method called from other object with same parameters returns cache");

	$obj1->as_method(1);
	is($called{as_method}, ++$count, "Method called from same object with different parameters executes");
}

sub expiration :Test(3) {
	my $self = shift;

	my $count = $called{expires} || 0;
	Memoize::Memcached::Attribute::Test::Class::expires(0..9);
	is($called{expires}, ++$count, "Function called");

	Memoize::Memcached::Attribute::Test::Class::expires(0..9);
	is($called{expires}, $count, "Function not called due to being cached");

	sleep 2;

	Memoize::Memcached::Attribute::Test::Class::expires(0..9);
	is($called{expires}, ++$count, "Function called again after cache expires");
}

1;

__END__
