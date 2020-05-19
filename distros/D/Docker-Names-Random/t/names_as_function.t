#!perl -T

use utf8;
use Test2::V0;
set_encoding('utf8');

use Docker::Names::Random qw( :all );

plan( tests => 2000 );

for (1..1000) {
    my $dn = docker_name();
    isnt( $dn, undef, 'Not undef' );
    like( $dn, qr/^ [[:word:]]{1,} _ [[:word:]]{1,} $/msx, 'Looks like a docker name' );
}

done_testing;

