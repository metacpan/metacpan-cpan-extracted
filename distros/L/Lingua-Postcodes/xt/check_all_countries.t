use strict;
use warnings;

use Test::More;

# This test is to confirm if the module covers all the countries
# of the world... according to Geography::Countries which is
# not installed by default, so reuires manual installation
use Geography::Countries;


use lib './lib';
use Lingua::Postcodes;

use utf8;

my @failed;
my @countries = Geography::Countries::code2;
    
my @no_postcode_system = qw/
    AE
    AG
    AN
    AO
    AQ
    AW
    BF
    BI
    BJ
    BS
    BV
    BW
    BZ
    CD
    CF
    CG
    CI
    CK
    CM
    DJ
    DM
    ER
    FJ
    GD
    GM
    GQ
    GY
    HK
    KI
    KM
    KP
    ML
    MO
    MR
    MU
    NR
    NU
    QA
    RW
    SB
    SC
    SL
    SR
    ST
    SY
    TF
    TG
    TK
    TO
    TP
    TV
    UG
    VU
    YE
    YU
    ZW
/;
for my $country (@countries) {
    SKIP: {
    if (grep {$_ eq $country } @no_postcode_system) {
            skip "$country does not have a postcode system";
            next;
    }
    my $postcode = Lingua::Postcodes::name($country);
    if (defined $postcode) {
        pass "$country should return a postcode";
    } else {
        push @failed, $country;
        my $name = Geography::Countries::country $country; 
        fail "$country ($name) should return a postcode";
    } 
    }
}

done_testing;