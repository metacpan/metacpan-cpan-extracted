#!perl

use Test::Most;
use MAD::Loader qw{ fqn };

my $prefix  = 'Foo::Bar';
my $add_inc = 't/lib';

my $loader = MAD::Loader->new( prefix => $prefix, add_inc => [$add_inc] );

subtest 'Before load' => sub {
    foreach my $module ( map { fqn( $_, $prefix ) } 1 .. 4 ) {
        ok( !$module->can('foo'), $module . '::foo() not found' );
    }
};

my $result = $loader->load( 1 .. 4 );
is_deeply(
    $result,
    {
        '4' => 'Foo::Bar::4',
        '3' => 'Foo::Bar::3',
        '2' => 'Foo::Bar::2',
        '1' => 'Foo::Bar::1',
    },
    'result of $loader->load()'
);

subtest 'After load' => sub {
    foreach my $module ( map { fqn( $_, $prefix ) } 1 .. 4 ) {
        ok( $module->can('foo'), $module . '::foo() found' );
    }
};

done_testing;
