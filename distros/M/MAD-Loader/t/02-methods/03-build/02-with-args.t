#!perl

use Test::Most;
use MAD::Loader;

my $loader = MAD::Loader->new(
    prefix  => 'Foo::Bar',
    set_inc => ['t/lib'],
    builder => 'new',
    args    => [42],
);

my $loaded = $loader->load( 1 .. 4 );
my $built  = $loader->build( values %{$loaded} );

foreach my $module ( sort keys %{$built} ) {
    subtest $module => sub {
        my $object = $built->{$module};

        isa_ok( $object, $module );
        can_ok( $object, 'foo' );
        is( $object->foo, 42, '$object->foo() eq 42' );
    };
}

done_testing;
