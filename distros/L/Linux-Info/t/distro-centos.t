use warnings;
use strict;
use Test::More;

my $class = 'Linux::Info::Distribution::OSRelease::CentOS';
require_ok($class);

my @fixtures = (
    [ 'get_name',                            'CentOS Linux' ],
    [ 'get_version',                         '7 (Core)' ],
    [ 'get_id',                              'centos' ],
    [ 'get_version_id',                      '7' ],
    [ 'get_pretty_name',                     'CentOS Linux 7 (Core)' ],
    [ 'get_ansi_color',                      '0;31' ],
    [ 'get_cpe_name',                        'cpe:/o:centos:centos:7' ],
    [ 'get_home_url',                        'https://www.centos.org/' ],
    [ 'get_bug_report_url',                  'https://bugs.centos.org/' ],
    [ 'get_centos_mantisbt_project',         'CentOS-7' ],
    [ 'get_centos_mantisbt_project_version', '7' ],
    [ 'get_redhat_support_product',          'centos' ],
    [ 'get_redhat_support_product_version',  '' ],
);

can_ok( $class, map { $_->[0] } @fixtures );
isa_ok( $class, 'Linux::Info::Distribution::OSRelease' );
my $instance = $class->new('t/samples/os-releases/centos');
isa_ok( $instance, $class );

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" );
}

is_deeply( $instance->get_id_like, [ 'rhel', 'fedora' ], 'get_id_like works' );

done_testing;
