#!perl -T

use utf8;
use Test2::V0;
set_encoding('utf8');

require Docker::Names::Random;

my $d  = Docker::Names::Random->new();
my $dn = $d->docker_name();

isnt( $dn, undef, 'Not undef' );

done_testing;

