use warnings;
use strict;
use Test::More;

use Linux::Info::Distribution::BasicInfo;

my $class = 'Linux::Info::Distribution::Custom::Amazon';
require_ok($class);
my $instance = $class->new(
    Linux::Info::Distribution::BasicInfo->new(
        'amazon', 't/samples/custom/amazon'
    )
);
ok( $instance, 'new method works' );
isa_ok( $instance, 'Linux::Info::Distribution::Custom' );

my @fixtures = (
    [ 'get_name',       'Amazon Linux' ],
    [ 'get_id',         'amazon' ],
    [ 'get_version_id', '2013.09' ],
    [ 'get_version',    '2013.09' ],
);

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works as expected" )
      or diag( explain($instance) );
}

done_testing;
