use warnings;
use strict;
use Test::More;

my $class = 'Linux::Info::Distribution::OSRelease::Rocky';
require_ok($class);

my @fixtures = (
    [ 'get_platform_id',                    'platform:el8' ],
    [ 'get_ansi_color',                     '0;32' ],
    [ 'get_logo',                           'fedora-logo-icon' ],
    [ 'get_cpe_name',                       'cpe:/o:rocky:rocky:8:GA' ],
    [ 'get_bug_report_url',                 'https://bugs.rockylinux.org/' ],
    [ 'get_support_end',                    '2029-05-31' ],
    [ 'get_rocky_support_product',          'Rocky-Linux-8' ],
    [ 'get_rocky_support_product_version',  '8.9' ],
    [ 'get_redhat_support_product',         'Rocky Linux' ],
    [ 'get_redhat_support_product_version', '8.9' ]
);

can_ok( $class, map { $_->[0] } @fixtures );

isa_ok( $class, 'Linux::Info::Distribution::OSRelease' );
my $instance = $class->new('t/samples/os-releases/rocky');
isa_ok( $instance, $class );

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" );
}

is_deeply(
    $instance->get_id_like,
    [ 'rhel', 'centos', 'fedora' ],
    'get_id_like works'
);

done_testing;
