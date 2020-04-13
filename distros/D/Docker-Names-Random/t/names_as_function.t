#!perl -T

use utf8;
use Test2::V0;
set_encoding('utf8');

use Docker::Names::Random qw( :all );

my $dn = docker_name();

isnt( $dn, undef, 'Not undef' );

done_testing;

