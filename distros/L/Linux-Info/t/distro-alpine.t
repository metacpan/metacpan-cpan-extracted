use warnings;
use strict;
use Test::More;

my $class = 'Linux::Info::Distribution::OSRelease::Alpine';
require_ok($class);

my @fixtures = (
    [ 'get_name',           'Alpine Linux' ],
    [ 'get_id',             'alpine' ],
    [ 'get_version_id',     '3.12.0' ],
    [ 'get_home_url',       'https://alpinelinux.org/' ],
    [ 'get_bug_report_url', 'https://bugs.alpinelinux.org/' ],
    [ 'get_version',        undef ],
);

can_ok( $class, map { $_->[0] } @fixtures );
isa_ok( $class, 'Linux::Info::Distribution::OSRelease' );
my $instance = $class->new('t/samples/os-releases/alpine');
isa_ok( $instance, $class );

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" );
}

done_testing;
