use warnings;
use strict;
use Test::More;

my $class = 'Linux::Info::Distribution::OSRelease::Debian';
require_ok($class);

my @fixtures = (
    [ 'get_pretty_name',      'Debian GNU/Linux 12 (bookworm)' ],
    [ 'get_name',             'Debian GNU/Linux' ],
    [ 'get_version_codename', 'bookworm' ],
    [ 'get_home_url',         'https://www.debian.org/' ],
    [ 'get_support_url',      'https://www.debian.org/support' ],
    [ 'get_bug_report_url',   'https://bugs.debian.org/' ],
);

can_ok( $class, map { $_->[0] } @fixtures );

isa_ok( $class, 'Linux::Info::Distribution::OSRelease' );
my $instance = $class->new('t/samples/os-releases/debian');
isa_ok( $instance, $class );

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" );
}

is_deeply( $instance->get_id_like, [], 'get_id_like works' );

done_testing;
