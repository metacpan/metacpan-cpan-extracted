#!perl

use Test::Most;
use MAD::Loader qw{ fqn };

local @INC = ('/foo/bar');

my $prefix = 'Foo::Bar';
my $loader;

subtest 'Before load' => sub {
    foreach my $module ( map { fqn( $_, $prefix ) } 1 .. 4 ) {
        ok( !$module->can('foo'), $module . '::foo() not found' );
    }
};

$loader = MAD::Loader->new( prefix => $prefix );

throws_ok { $loader->load(1) }
qr{Can.t locate Foo/Bar/1.pm in .INC},
  'Modules are not within @INC';

$loader = MAD::Loader->new( prefix => $prefix, set_inc => ['t/lib'] );
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

is_deeply( $loader->inc, ['t/lib'],    'Internal @INC of loader is ["t/lib"]' );
is_deeply( \@INC,        ['/foo/bar'], 'Global @INC is untouchable' );

done_testing;
