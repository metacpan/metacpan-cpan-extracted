#!perl

use Test::Most;
use MAD::Loader;

my $loader = MAD::Loader->new(
    prefix  => 'Foo::Bar',
    set_inc => ['t/lib'],
    builder => 'new',
);

my $loaded = $loader->load( 1 .. 4 );
my $built  = $loader->build( values %{$loaded} );

foreach my $module ( sort keys %{$built} ) {
    subtest $module => sub {
        my $object = $built->{$module};
        my $name = ( split m{::}, $module )[-1];

        isa_ok( $object, $module );
        can_ok( $object, 'foo' );
        is( $object->foo, $name, '$object->foo() eq ' . $name );
    };
}

done_testing;
