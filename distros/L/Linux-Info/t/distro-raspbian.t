use warnings;
use strict;
use Test::More;

my $class = 'Linux::Info::Distribution::OSRelease::Raspbian';
require_ok($class);

my @fixtures = (
    [ 'get_name',             'Raspbian GNU/Linux' ],
    [ 'get_id',               'raspbian' ],
    [ 'get_version_id',       13 ],
    [ 'get_home_url',         'http://www.raspbian.org/' ],
    [ 'get_version',          '13 (trixie)' ],
    [ 'get_pretty_name',      'Raspbian GNU/Linux trixie/sid' ],
    [ 'get_version_codename', 'trixie' ],
    [ 'get_support_url',      'http://www.raspbian.org/RaspbianForums' ],
    [ 'get_bug_report_url',   'http://www.raspbian.org/RaspbianBugs' ],
);

can_ok( $class, map { $_->[0] } @fixtures );
isa_ok( $class, 'Linux::Info::Distribution::OSRelease' );
my $instance = $class->new('t/samples/os-releases/raspbian');
isa_ok( $instance, $class );

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" );
}

is_deeply( $instance->get_id_like, ['debian'], 'get_id_like works' );

done_testing;
