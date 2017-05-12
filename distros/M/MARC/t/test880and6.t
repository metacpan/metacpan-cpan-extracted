#!perl

#Tests for field 880 and for subfield 6

use strict;
use warnings;
use File::Spec;
use Test::More tests=>6;

BEGIN { use_ok( 'MARC::File::USMARC' ); }
BEGIN { use_ok( 'MARC::Lint' ); }

FROM_TEXT: {
    my $marc = MARC::Record->new();
    isa_ok( $marc, 'MARC::Record', 'MARC record' );

    $marc->leader("00000nam  22002538a 4500"); 

    my $nfields = $marc->add_fields(
        ['001', 'ttt07000001 '],
        ['003', 'TEST '],
        ['008', '070520s2007    ilu           000 0 eng d',
        ],
        ['040', "", "",
            a => 'TEST',
            c => 'TEST',
         ],
        ['050', "", "4",
            a => 'RZ999',
            b => '.J66 2007',
         ],
        ['082', "0", "4",
            a => '615.8/9',
            2 => '22'
         ],
        [100, "1","", 
            a => "Jones, John.",
        ],
        [245, "1","0",
            6 => "880-02",
            a => "Test 880.",
        ],
        [260, "", "",
            a => "Mount Morris, Ill. :",
            b => "B. Baldus,",
            c => "2007.",
            ],
        [300, "", "",
            a => "1 v. ;",
            c => "23 cm.",
        ],
        [880, "1", "0",
            6 => '245-02/$1',
            a => "<Title in CJK script>.",
        ],
    );
    is( $nfields, 11, "All the fields added OK" );

    my @expected = (
#        (undef),
        #q{},
    );

    my $lint = new MARC::Lint;
    isa_ok( $lint, 'MARC::Lint' );

    $lint->check_record( $marc );
    my @warnings = $lint->warnings;
    while ( @warnings ) {
        my $expected = shift @expected;
        my $actual = shift @warnings;

        is( $actual, $expected, "Checking expected messages" );
    }
    is( scalar @expected, 0, "All expected messages exhausted." );
}

