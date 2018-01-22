#! /usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Test::Exception;

use Locale::Country::OFAC qw( get_sanction_by_code is_region_sanctioned );
use Readonly;

Readonly my $NON_SANCTIONED_STATUS => 0;
Readonly my $SANCTIONED_STATUS     => 1;
Readonly my $LOWER_RANGE_MIN       => 95000;
Readonly my $HIGHER_RANGE_MIN      => 295000;
Readonly my $MAX                   => 5000;


cmp_ok( get_sanction_by_code('DE'),
    '==', $NON_SANCTIONED_STATUS, 'Germany not sanctioned' );

cmp_ok( get_sanction_by_code('IR'),
    '==', $SANCTIONED_STATUS, 'Iran is sanctioned' );

cmp_ok( get_sanction_by_code('CU'),
    '==', $SANCTIONED_STATUS, 'Cuba is sanctioned' );

cmp_ok( get_sanction_by_code('KP'),
    '==', $SANCTIONED_STATUS, 'North Korea is sanctioned' );

cmp_ok( get_sanction_by_code('SY'),
    '==', $SANCTIONED_STATUS, 'Syria is sanctioned' );

cmp_ok( get_sanction_by_code('IRN'),
    '==', $SANCTIONED_STATUS, 'Iran is sanctioned' );

cmp_ok( get_sanction_by_code('CUB'),
    '==', $SANCTIONED_STATUS, 'Cuba is sanctioned' );

cmp_ok( get_sanction_by_code('PRK'),
    '==', $SANCTIONED_STATUS, 'North Korea is sanctioned' );

cmp_ok( get_sanction_by_code('SYR'),
    '==', $SANCTIONED_STATUS, 'Syria is sanctioned' );

cmp_ok( get_sanction_by_code('UA'),
    '==', $NON_SANCTIONED_STATUS, 'Ukraine not sanctioned (entirely)' );

cmp_ok( get_sanction_by_code('RU'),
    '==', $NON_SANCTIONED_STATUS, 'Russia not sanctioned (entirely)' );

dies_ok { is_region_sanctioned( 'DE', '') };

dies_ok { is_region_sanctioned('', 123456) };

my $random_num = int( rand($MAX) ) + $LOWER_RANGE_MIN;

cmp_ok( is_region_sanctioned('RU', $LOWER_RANGE_MIN - 1 ), '==',
    $NON_SANCTIONED_STATUS, 'Zip just below range not sanctioned');

cmp_ok( is_region_sanctioned('RU', $LOWER_RANGE_MIN + $MAX + 1 ), '==',
    $NON_SANCTIONED_STATUS, 'Zip just above range not sanctioned');

cmp_ok( is_region_sanctioned('RU', $HIGHER_RANGE_MIN - 1 ), '==',
    $NON_SANCTIONED_STATUS, 'Zip just below range not sanctioned');

cmp_ok( is_region_sanctioned('RU', $HIGHER_RANGE_MIN + $MAX + 1 ), '==',
    $NON_SANCTIONED_STATUS, 'Zip just above range not sanctioned');

cmp_ok( is_region_sanctioned('RU', $random_num) , '==', $SANCTIONED_STATUS,
    'Russian Crimean zip correctly sanctioned' );

cmp_ok( is_region_sanctioned('RUS', $random_num), '==', $SANCTIONED_STATUS,
    'Russian Crimean zip correctly sanctioned' );

cmp_ok( is_region_sanctioned('UA', $random_num), '==', $SANCTIONED_STATUS,
    'Ukraine Crimean zip correctly sanctioned' );

cmp_ok( is_region_sanctioned('UKR', $random_num), '==', $SANCTIONED_STATUS,
    'Ukraine Crimean zip correctly sanctioned' );

my $random_int = int( rand($MAX) ) + $HIGHER_RANGE_MIN;

cmp_ok( is_region_sanctioned('RU', $random_int ), '==', $SANCTIONED_STATUS,
    'Russian Crimean zip correctly sanctioned' );

cmp_ok( is_region_sanctioned('RUS', $random_int ), '==', $SANCTIONED_STATUS,
    'Russian Crimean zip correctly sanctioned' );

cmp_ok( is_region_sanctioned('UA', $random_int ), '==', $SANCTIONED_STATUS,
    'Ukraine Crimean zip correctly sanctioned' );

cmp_ok( is_region_sanctioned('UKR', $random_int ), '==', $SANCTIONED_STATUS,
    'Ukraine Crimean zip correctly sanctioned' );

cmp_ok( is_region_sanctioned('DE', 12345), '==', $NON_SANCTIONED_STATUS,
    'Germany zip correctly not sanctioned' );

done_testing;
