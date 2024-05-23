use warnings;
use strict;
use Test::More;

my $class = 'Linux::Info::Distribution::OSRelease::Ubuntu';
require_ok($class);

my @fixtures = (
    [ 'get_pretty_name',      'Ubuntu 22.04.4 LTS' ],
    [ 'get_version_codename', 'jammy' ],
    [ 'get_home_url',         'https://www.ubuntu.com/' ],
    [ 'get_support_url',      'https://help.ubuntu.com/' ],
    [ 'get_bug_report_url',   'https://bugs.launchpad.net/ubuntu/' ],
    [
        'get_privacy_policy_url',
        'https://www.ubuntu.com/legal/terms-and-policies/privacy-policy'
    ],
    [ 'get_ubuntu_codename', 'jammy' ],
);

can_ok( $class, map { $_->[0] } @fixtures );

isa_ok( $class, 'Linux::Info::Distribution::OSRelease' );
my $instance = $class->new('t/samples/os-release');
isa_ok( $instance, $class );

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" );
}

is_deeply( $instance->get_id_like, ['debian'] );

done_testing;
