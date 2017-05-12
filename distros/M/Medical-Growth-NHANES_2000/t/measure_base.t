#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 18;

use FindBin;
use lib "$FindBin::Bin/lib";

require_ok('Medical::Growth::NHANES_2000::Base');

require My_Test_Base;
my $h = My_Test_Base->new;

ok( defined \&My_Test_Base::_params_LMS, '_params_LMS set up' );

is_deeply(
    $h->_params_LMS,
    [
        { index => 1, L => 0, M => 1, S => 1 },
        { index => 2, L => 2, M => 2, S => 2 },
        { index => 3, L => 3, M => 3, S => 3 }
    ],
    '_build_params_LMS'
);

is_deeply( [ $h->lookup_LMS(2) ], [ 2, 2, 2 ], 'lookup_LMS: exact match' );

is_deeply(
    [ $h->lookup_LMS(1.5) ],
    [ 1, 1.5, 1.5 ],
    'lookup_LMS: interpolates'
);

ok( !defined $h->lookup_LMS,    'lookup_LMS: no index' );
ok( !defined $h->lookup_LMS(0), 'lookup_LMS: index too low' );
ok( !defined $h->lookup_LMS(4), 'lookup_LMS: index too high' );

is( int( $h->z_for_value( 2, 1 ) * 1000 ) / 1000,
    0.693, 'z_for_value: index in range, l == 0' );
is( $h->z_for_value( 4, 2 ), 0.75, 'z_for_value: index in range, l != 0' );
ok( !defined $h->z_for_value( 1, 4 ), 'z_for_value: index out of range' );

is( $h->pct_for_value( 2, 2 ), 50, 'pct_for_value: index in range' );
ok( !defined $h->pct_for_value( 1, 4 ), 'pct_for_value: index out of range' );

is( int( $h->value_for_z( 0.69, 1 ) + 0.01 ),
    2, 'z_for_value: index in range, l == 0' );
is( $h->value_for_z( 2, 2 ), 6, 'value_for_z:index in range, l != 0' );
ok( !defined $h->value_for_z( 2, 4 ), 'value_for_z: index out of range' );

is( $h->value_for_pct( 50, 1 ), 1, 'value_for_pct: index in range' );
ok( !defined $h->value_for_pct( -5, 4 ), 'value_for_pct: index out of range' );
