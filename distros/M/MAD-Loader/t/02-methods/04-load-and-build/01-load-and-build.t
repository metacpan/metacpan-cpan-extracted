#!perl

use Test::Most;
use MAD::Loader;

my ( $loader, $built );

$loader = MAD::Loader->new(
    prefix  => 'Foo::Bar',
    set_inc => ['t/lib'],
    builder => 'new',
);

$built = $loader->load_and_build( 1 .. 4 );

foreach my $module ( sort keys %{$built} ) {
    subtest "$module without args" => sub {
        my $object = $built->{$module};
        my $name = ( split m{::}, $module )[-1];

        isa_ok( $object, $module );
        can_ok( $object, 'foo' );
        is( $object->foo, $name, '$object->foo() eq ' . $name );
    };
}

no warnings 'once';
is_deeply(
    \@Foo::Bar::0::build_order,
    [
        qw{
          Foo::Bar::1
          Foo::Bar::2
          Foo::Bar::3
          Foo::Bar::4
          }
    ],
    'Build order must be the same as load order',
);
use warnings;

$loader = MAD::Loader->new(
    prefix  => 'Foo::Bar',
    set_inc => ['t/lib'],
    builder => 'new',
    args    => [42],
);

$built = $loader->load_and_build( 1 .. 4 );

foreach my $module ( sort keys %{$built} ) {
    subtest "$module with args" => sub {
        my $object = $built->{$module};

        isa_ok( $object, $module );
        can_ok( $object, 'foo' );
        is( $object->foo, 42, '$object->foo() eq 42' );
    };
}

done_testing;
