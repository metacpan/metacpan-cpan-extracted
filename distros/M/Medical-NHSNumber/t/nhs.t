#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use_ok('Medical::NHSNumber');


my $rah_tests = [
    { 
       'number' => 123,
       'valid'  => undef,
       'text'   => 'Too short'
    },

    { 
       'number' => 'ABCJKLPOIP',
       'valid'  => undef,
       'text'   => 'contains characters'
    },

    ## taken from http://www.sath.nhs.uk/patient_information/nhsnumber.asp
    ## this is an *example* number only.

    { 
       'number' => '4505577104',
       'valid'  => 1,
       'text'   => 'valid number'
    },

    { 
       'number' => '1111111121',
       'valid'  => undef,
       'text'   => 'invalid number'
    },

    { 
       'number' => '4505577108',
       'valid'  => undef,
       'text'   => 'valid number'
    },

];

foreach my $rh_test ( @$rah_tests ) {
    is(
        Medical::NHSNumber::is_valid( $rh_test->{number} ),
        $rh_test->{valid},
        $rh_test->{text}
    );
    
}

my $silly    = '12345';
my @is_valid = Medical::NHSNumber::is_valid($silly);
ok( ! @is_valid, 'List-context test' );
