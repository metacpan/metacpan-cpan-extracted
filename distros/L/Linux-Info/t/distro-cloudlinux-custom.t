use warnings;
use strict;
use Test::More;

use Linux::Info::Distribution::BasicInfo;

my $class = 'Linux::Info::Distribution::Custom::CloudLinux';
require_ok($class);

my @fixtures = (
    [ 'get_name',     'CloudLinux Server' ],
    [ 'get_version',  '5.11' ],
    [ 'get_codename', 'Vladislav Volkov' ],
    [ 'get_id',       'CloudLinux' ],
);

can_ok( $class, map { $_->[0] } @fixtures );

my $instance = $class->new(
    Linux::Info::Distribution::BasicInfo->new(
        'CloudLinux', 't/samples/custom/cloudlinux'
    )
);
ok( $instance, 'new method works' );
isa_ok( $instance, 'Linux::Info::Distribution::Custom' );

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" )
      or diag( explain($instance) );
}

done_testing;
