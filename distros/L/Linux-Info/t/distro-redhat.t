use warnings;
use strict;
use Test::More;

my $class = 'Linux::Info::Distribution::OSRelease::RedHat';
require_ok($class);

my @fixtures = (
    [ 'get_pretty_name',             'Red Hat Enterprise Linux 8.4 (Ootpa)' ],
    [ 'get_name',                    'Red Hat Enterprise Linux' ],
    [ 'get_version',                 '8.4 (Ootpa)' ],
    [ 'get_version_id',              '8.4' ],
    [ 'get_cpe_name',                'cpe:/o:redhat:enterprise_linux:8.4:GA' ],
    [ 'get_home_url',                'https://www.redhat.com/' ],
    [ 'get_ansi_color',              '0;31' ],
    [ 'get_id',                      'rhel' ],
    [ 'get_platform_id',             'platform:el8' ],
    [ 'get_bug_report_url',          'https://bugzilla.redhat.com/' ],
    [ 'get_redhat_bugzilla_product', 'Red Hat Enterprise Linux 8' ],
    [ 'get_redhat_bugzilla_product_version', '8.4' ],
    [ 'get_redhat_support_product',          'Red Hat Enterprise Linux' ],
    [ 'get_redhat_support_product_version',  '8.4' ],
);

can_ok( $class, map { $_->[0] } @fixtures );
isa_ok( $class, 'Linux::Info::Distribution::OSRelease' );
my $instance = $class->new('t/samples/os-releases/redhat');
isa_ok( $instance, $class );

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" );
}

is_deeply( $instance->get_id_like, ['fedora'], 'get_id_like works' );

done_testing;
