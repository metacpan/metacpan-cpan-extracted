use warnings;
use strict;
use Test::More;

use Linux::Info::Distribution::BasicInfo;

my $class = 'Linux::Info::Distribution::Custom::RedHat';
require_ok($class);
can_ok( $class, qw(get_type is_enterprise get_codename) );

my $instance = $class->new(
    Linux::Info::Distribution::BasicInfo->new(
        'redhat', 't/samples/redhat_version'
    )
);
ok( $instance, 'new method works' );
isa_ok( $instance, 'Linux::Info::Distribution::Custom' );

my @fixtures = (
    [ 'get_name',       'Red Hat Linux Enterprise Server' ],
    [ 'get_type',       'Server' ],
    [ 'get_codename',   'Maipo' ],
    [ 'get_version',    'release 7.2, codename Maipo' ],
    [ 'get_version_id', '7.2' ],
    [ 'get_id',         'redhat' ],
);

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" )
      or diag( explain($instance) );
}

ok( $instance->is_enterprise, 'the distro is Enterprise' )
  or diag( explain($instance) );

done_testing;
