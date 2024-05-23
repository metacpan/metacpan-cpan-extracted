use warnings;
use strict;
use Test::More;

my $class = 'Linux::Info::Distribution::OSRelease::Amazon';
require_ok($class);

my @fixtures = (
    [ 'get_pretty_name', 'Amazon Linux 2' ],
    [ 'get_name',        'Amazon Linux' ],
    [ 'get_version',     '2' ],
    [ 'get_id',          'amzn' ],
    [ 'get_cpe_name',    'cpe:2.3:o:amazon:amazon_linux:2' ],
    [ 'get_home_url',    'https://amazonlinux.com/' ],
    [ 'get_ansi_color',  '0;33' ],
);

can_ok( $class, map { $_->[0] } @fixtures );
isa_ok( $class, 'Linux::Info::Distribution::OSRelease' );
my $instance = $class->new('t/samples/os-releases/amazon');
isa_ok( $instance, $class );

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" );
}

is_deeply(
    $instance->get_id_like,
    [ 'centos', 'rhel', 'fedora' ],
    'get_id_like works'
);

done_testing;
