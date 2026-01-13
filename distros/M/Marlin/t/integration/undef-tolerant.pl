use Test2::V0;
use Data::Dumper;

{
	package MyClass;
	use Types::Common -types;
	use Marlin ':UndefTolerant',
		'foo1?' => Bool,
		'foo2?' => Str;
}

my $o = MyClass->new( foo1 => undef, foo2 => undef );

# Undef is a legitimate value for Bool attributes; it means false!
ok( $o->has_foo1 );

# Undef is not a string.
ok( !$o->has_foo2 );

done_testing;