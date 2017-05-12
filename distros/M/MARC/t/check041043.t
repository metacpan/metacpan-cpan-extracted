#!perl

#This tests check_041() and check_043() called separately
#See lint.t for testing through check_record()

use strict;
use warnings;
use Test::More tests=>18;

BEGIN { use_ok( 'MARC::Field' ); }
BEGIN { use_ok( 'MARC::Lint' ); }

my $lint = new MARC::Lint;
isa_ok( $lint, 'MARC::Lint' );

my @fields = ( 
    ['041', "0","", 
        a => 'end', #invalid
        a => 'span', #too long
        h => 'far', #opsolete
    ],
    ['041', "1","", 
        a => 'endorviwo', #invalid
        a => 'spanowpalasba', #too long and invalid
    ],
    ['043', "","",
        a => 'n-----', #6 chars vs. 7
        a => 'n-us----', #8 chars vs. 7
        a => 'n-ma-us', #invalid code
        a => 'e-ur-ai', #obsolete code
    ],

);

my @expected = (
    q{041: Subfield _a, end (end), is not valid.},
    q{041: Subfield _a must be evenly divisible by 3 or exactly three characters if ind2 is not 7, (span).},
    q{041: Subfield _h, far, may be obsolete.},
    q{041: Subfield _a, endorviwo (end), is not valid.},
    q{041: Subfield _a, endorviwo (orv), is not valid.},
    q{041: Subfield _a, endorviwo (iwo), is not valid.},
    q{041: Subfield _a must be evenly divisible by 3 or exactly three characters if ind2 is not 7, (spanowpalasba).},
    q{043: Subfield _a must be exactly 7 characters, n-----},
    q{043: Subfield _a must be exactly 7 characters, n-us----},
    q{043: Subfield _a, n-ma-us, is not valid.},
    q{043: Subfield _a, e-ur-ai, may be obsolete.},

);

foreach my $field (@fields) {
    my $field_object = MARC::Field->new( @$field );
    isa_ok( $field_object, 'MARC::Field', 'MARC field' );

    my $check_tag = "check_".$field_object->tag();
    $lint->$check_tag( $field_object );
    my @warnings = $lint->warnings;
    $lint->clear_warnings();
    while ( @warnings ) {
        my $expected = shift @expected;
        my $actual = shift @warnings;

        is( $actual, $expected, "Checking expected messages, $expected" );
    }
} #foreach field

is( scalar @expected, 0, "All expected messages exhausted." );
