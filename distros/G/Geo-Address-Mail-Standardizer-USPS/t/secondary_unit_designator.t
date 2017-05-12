#!/usr/bin/perl

use Test::More;
use strict;

use Geo::Address::Mail::US;
use Geo::Address::Mail::Standardizer::USPS;

my $std = Geo::Address::Mail::Standardizer::USPS->new;

my %secondary_unit_designator = (
    'APT-00' => {
        'input'  => '23 Something APARTMENT',
        'output' => '23 SOMETHING APT'
    },
    'APT-01' => {
        'input'  => '23 Something APT',
        'output' => '23 SOMETHING APT'
    },
    'APT-02' => {
        'input'  => '23 Something APT.',
        'output' => '23 SOMETHING APT'
    },
    'BLDG-00' => {
        'input'  => '23 Something BLDG',
        'output' => '23 SOMETHING BLDG'
    },
    'BLDG-01' => {
        'input'  => '23 Something BLDG.',
        'output' => '23 SOMETHING BLDG'
    },
    'BLDG-02' => {
        'input'  => '23 Something BUILDING',
        'output' => '23 SOMETHING BLDG'
    },
    'BSMT-00' => {
        'input'  => '23 Something BASEMENT',
        'output' => '23 SOMETHING BSMT'
    },
    'BSMT-01' => {
        'input'  => '23 Something BSMT',
        'output' => '23 SOMETHING BSMT'
    },
    'BSMT-02' => {
        'input'  => '23 Something BSMT.',
        'output' => '23 SOMETHING BSMT'
    },
    'DEPT-00' => {
        'input'  => '23 Something DEPARTMENT',
        'output' => '23 SOMETHING DEPT'
    },
    'DEPT-01' => {
        'input'  => '23 Something DEPT',
        'output' => '23 SOMETHING DEPT'
    },
    'DEPT-02' => {
        'input'  => '23 Something DEPT.',
        'output' => '23 SOMETHING DEPT'
    },
    'FL-00' => {
        'input'  => '23 Something FL',
        'output' => '23 SOMETHING FL'
    },
    'FL-01' => {
        'input'  => '23 Something FL.',
        'output' => '23 SOMETHING FL'
    },
    'FL-02' => {
        'input'  => '23 Something FLOOR',
        'output' => '23 SOMETHING FL'
    },
    'FRNT-00' => {
        'input'  => '23 Something FRNT',
        'output' => '23 SOMETHING FRNT'
    },
    'FRNT-01' => {
        'input'  => '23 Something FRNT.',
        'output' => '23 SOMETHING FRNT'
    },
    'FRNT-02' => {
        'input'  => '23 Something FRONT',
        'output' => '23 SOMETHING FRNT'
    },
    'HNGR-00' => {
        'input'  => '23 Something HANGER',
        'output' => '23 SOMETHING HNGR'
    },
    'HNGR-01' => {
        'input'  => '23 Something HNGR',
        'output' => '23 SOMETHING HNGR'
    },
    'HNGR-02' => {
        'input'  => '23 Something HNGR.',
        'output' => '23 SOMETHING HNGR'
    },
    'LBBY-00' => {
        'input'  => '23 Something LBBY',
        'output' => '23 SOMETHING LBBY'
    },
    'LBBY-01' => {
        'input'  => '23 Something LBBY.',
        'output' => '23 SOMETHING LBBY'
    },
    'LBBY-02' => {
        'input'  => '23 Something LOBBY',
        'output' => '23 SOMETHING LBBY'
    },
    'LOT-00' => {
        'input'  => '23 Something LOT',
        'output' => '23 SOMETHING LOT'
    },
    'LOT-01' => {
        'input'  => '23 Something LOT.',
        'output' => '23 SOMETHING LOT'
    },
    'LOWR-00' => {
        'input'  => '23 Something LOWER',
        'output' => '23 SOMETHING LOWR'
    },
    'LOWR-01' => {
        'input'  => '23 Something LOWR',
        'output' => '23 SOMETHING LOWR'
    },
    'LOWR-02' => {
        'input'  => '23 Something LOWR.',
        'output' => '23 SOMETHING LOWR'
    },
    'OFC-00' => {
        'input'  => '23 Something OFC',
        'output' => '23 SOMETHING OFC'
    },
    'OFC-01' => {
        'input'  => '23 Something OFC.',
        'output' => '23 SOMETHING OFC'
    },
    'OFC-02' => {
        'input'  => '23 Something OFFICE',
        'output' => '23 SOMETHING OFC'
    },
    'PH-00' => {
        'input'  => '23 Something PENTHOUSE',
        'output' => '23 SOMETHING PH'
    },
    'PH-01' => {
        'input'  => '23 Something PH',
        'output' => '23 SOMETHING PH'
    },
    'PH-02' => {
        'input'  => '23 Something PH.',
        'output' => '23 SOMETHING PH'
    },
    'PIER-00' => {
        'input'  => '23 Something PIER',
        'output' => '23 SOMETHING PIER'
    },
    'PIER-01' => {
        'input'  => '23 Something PIER.',
        'output' => '23 SOMETHING PIER'
    },
    'REAR-00' => {
        'input'  => '23 Something REAR',
        'output' => '23 SOMETHING REAR'
    },
    'REAR-01' => {
        'input'  => '23 Something REAR.',
        'output' => '23 SOMETHING REAR'
    },
    'RM-00' => {
        'input'  => '23 Something RM',
        'output' => '23 SOMETHING RM'
    },
    'RM-01' => {
        'input'  => '23 Something RM.',
        'output' => '23 SOMETHING RM'
    },
    'RM-02' => {
        'input'  => '23 Something ROOM',
        'output' => '23 SOMETHING RM'
    },
    'SIDE-00' => {
        'input'  => '23 Something SIDE',
        'output' => '23 SOMETHING SIDE'
    },
    'SIDE-01' => {
        'input'  => '23 Something SIDE.',
        'output' => '23 SOMETHING SIDE'
    },
    'SLIP-00' => {
        'input'  => '23 Something SLIP',
        'output' => '23 SOMETHING SLIP'
    },
    'SLIP-01' => {
        'input'  => '23 Something SLIP.',
        'output' => '23 SOMETHING SLIP'
    },
    'SPC-00' => {
        'input'  => '23 Something SPACE',
        'output' => '23 SOMETHING SPC'
    },
    'SPC-01' => {
        'input'  => '23 Something SPC',
        'output' => '23 SOMETHING SPC'
    },
    'SPC-02' => {
        'input'  => '23 Something SPC.',
        'output' => '23 SOMETHING SPC'
    },
    'STE-00' => {
        'input'  => '23 Something STE',
        'output' => '23 SOMETHING STE'
    },
    'STE-01' => {
        'input'  => '23 Something STE.',
        'output' => '23 SOMETHING STE'
    },
    'STE-02' => {
        'input'  => '23 Something SUITE',
        'output' => '23 SOMETHING STE'
    },
    'STOP-00' => {
        'input'  => '23 Something STOP',
        'output' => '23 SOMETHING STOP'
    },
    'STOP-01' => {
        'input'  => '23 Something STOP.',
        'output' => '23 SOMETHING STOP'
    },
    'TRLR-00' => {
        'input'  => '23 Something TRAILER',
        'output' => '23 SOMETHING TRLR'
    },
    'TRLR-01' => {
        'input'  => '23 Something TRLR',
        'output' => '23 SOMETHING TRLR'
    },
    'TRLR-02' => {
        'input'  => '23 Something TRLR.',
        'output' => '23 SOMETHING TRLR'
    },
    'UNIT-00' => {
        'input'  => '23 Something UNIT',
        'output' => '23 SOMETHING UNIT'
    },
    'UNIT-01' => {
        'input'  => '23 Something UNIT.',
        'output' => '23 SOMETHING UNIT'
    },
    'UPPR-00' => {
        'input'  => '23 Something UPPER',
        'output' => '23 SOMETHING UPPR'
    },
    'UPPR-01' => {
        'input'  => '23 Something UPPR',
        'output' => '23 SOMETHING UPPR'
    },
    'UPPR-02' => {
        'input'  => '23 Something UPPR.',
        'output' => '23 SOMETHING UPPR'
    }
);

foreach my $k ( sort keys %secondary_unit_designator ) {
    my $address = Geo::Address::Mail::US->new(
        name        => 'Test Testerson',
        street      => $secondary_unit_designator{$k}{input},
        street2     => q{ },
        city        => 'Testville',
        state       => 'TN',
        postal_code => '12345'
    );

    my $res  = $std->standardize($address);
    my $corr = $res->standardized_address;
    cmp_ok(
        $res->standardized_address->street,     'eq',
        $secondary_unit_designator{$k}{output}, $k
    );

}

done_testing;

