#!perl

#This tests check_020() called separately
#See lint.t for testing through check_record()

use strict;
use warnings;
use Test::More tests=>28;

BEGIN { use_ok( 'MARC::Field' ); }
BEGIN { use_ok( 'MARC::Lint' ); }

my $lint = new MARC::Lint;
isa_ok( $lint, 'MARC::Lint' );

my @fields = ( 
        ['020', "","",
            a => "154879473", #too few digits
        ],
        ['020', "","",
            a => "1548794743", #invalid checksum
        ],
        ['020', "","",
            a => "15487947443", #11 digits
        ],
        ['020', "","",
            a => "15487947443324", #14 digits
        ],
        ['020', "","",
            a => "9781548794743", #13 digit valid
        ],
        ['020', "","",
            a => "9781548794745", #13 digit invalid
        ],
        ['020', "","",
            a => "1548794740 (10 : good checksum)", #10 digit valid with qualifier
        ],
        ['020', "","",
            a => "1548794745 (10 : bad checksum)", #10 digit invalid with qualifier
        ],
        ['020', "","",
            a => "1-54879-474-0 (hyphens and good checksum)", #10 digit invalid with hyphens and qualifier
        ],
        ['020', "","",
            a => "1-54879-474-5 (hyphens and bad checksum)", #10 digit invalid with hyphens and qualifier
        ],
        ['020', "","",
            a => "1548794740(10 : unspaced qualifier)", #10 valid without space before qualifier
        ],
        ['020', "","",
            a => "1548794745(10 : unspaced qualifier : bad checksum)", #10 invalid without space before qualifier
        ],

        ['020', "","",
            z => "1548794743", #subfield z
        ],

);

my @expected = (
    q{020: Subfield a has the wrong number of digits, 154879473.},
    q{020: Subfield a has bad checksum, 1548794743.},
    q{020: Subfield a has the wrong number of digits, 15487947443.},
    q{020: Subfield a has the wrong number of digits, 15487947443324.},
    q{020: Subfield a has bad checksum (13 digit), 9781548794745.},
    q{020: Subfield a has bad checksum, 1548794745 (10 : bad checksum).},
    q{020: Subfield a may have invalid characters.},
    q{020: Subfield a may have invalid characters.},
    q{020: Subfield a has bad checksum, 1-54879-474-5 (hyphens and bad checksum).},
    q{020: Subfield a qualifier must be preceded by space, 1548794740(10 : unspaced qualifier).},
    q{020: Subfield a qualifier must be preceded by space, 1548794745(10 : unspaced qualifier : bad checksum).},
    q{020: Subfield a has bad checksum, 1548794745(10 : unspaced qualifier : bad checksum).},

);

foreach my $field (@fields) {
    my $field_object = MARC::Field->new( @$field );
    isa_ok( $field_object, 'MARC::Field', (join "", "MARC field, ", $field_object->subfield('a'))  ) if $field_object->subfield('a');

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
