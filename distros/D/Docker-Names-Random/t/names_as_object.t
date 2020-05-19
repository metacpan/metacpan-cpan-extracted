#!perl -T

use utf8;
use Test2::V0;
set_encoding('utf8');

require Docker::Names::Random;

plan( tests => 4000 );

for (1..1000) {
    my $d  = Docker::Names::Random->new();
    my $dn = $d->docker_name();

    isnt( $dn, undef, 'Not undef' );
    like( $dn, qr/^ [[:word:]]{1,} _ [[:word:]]{1,} $/msx, 'Looks like a docker name' );
}

my $d  = Docker::Names::Random->new();
my @dns;
for (1..1000) {
    my $dn = $d->docker_name();

    isnt( $dn, undef, 'Not undef' );
    like( $dn, qr/^ [[:word:]]{1,} _ [[:word:]]{1,} $/msx, 'Looks like a docker name' );
    push( @dns, $dn );
}

done_testing;

