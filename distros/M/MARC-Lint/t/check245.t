#!perl

#This tests check_245() called separately
#See lint.t for testing through check_record()

use strict;
use warnings;
use Test::More tests=>60;

BEGIN { use_ok( 'MARC::Field' ); }
BEGIN { use_ok( 'MARC::Lint' ); }

my $lint = new MARC::Lint;
isa_ok( $lint, 'MARC::Lint' );

my @fields = ( 
    [245, '0', '0', 'a', 'Subfield a.'],
    [245, '0', '0', 'b', 'no subfield a.'],
    [245, '0', '0', 'a', 'No period at end'],
    [245, '0', '0', 'a', 'Other punctuation not followed by period!'],
    [245, '0', '0', 'a', 'Other punctuation not followed by period?'],
    [245, '0', '0', 'a', 'Precedes sub c', 'c', 'not preceded by space-slash.'],
    [245, '0', '0', 'a', 'Precedes sub c/', 'c', 'not preceded by space-slash.'],
    [245, '0', '0', 'a', 'Precedes sub c /', 'c', 'initials in sub c B. B.'],
    [245, '0', '0', 'a', 'Precedes sub c /', 'c', 'initials in sub c B.B. (no warning).'],
    [245, '0', '0', 'a', 'Precedes sub b', 'b', 'not preceded by proper punctuation.'],
    [245, '0', '0', 'a', 'Precedes sub b=', 'b', 'not preceded by proper punctuation.'],
    [245, '0', '0', 'a', 'Precedes sub b:', 'b', 'not preceded by proper punctuation.'],
    [245, '0', '0', 'a', 'Precedes sub b;', 'b', 'not preceded by proper punctuation.'],
    [245, '0', '0', 'a', 'Precedes sub b =', 'b', 'preceded by proper punctuation.'],
    [245, '0', '0', 'a', 'Precedes sub b :', 'b', 'preceded by proper punctuation.'],
    [245, '0', '0', 'a', 'Precedes sub b ;', 'b', 'preceded by proper punctuation.'],
    [245, '0', '0', 'a', 'Precedes sub h ', 'h', '[videorecording].'],
    [245, '0', '0', 'a', 'Precedes sub h-- ', 'h', '[videorecording] :', 'b', 'with elipses dash before h.'],
    [245, '0', '0', 'a', 'Precedes sub h-- ', 'h', 'videorecording :', 'b', 'without brackets around GMD.'],
    [245, '0', '0', 'a', 'Precedes sub n.', 'n', 'Number 1.'],
    [245, '0', '0', 'a', 'Precedes sub n', 'n', 'Number 2.'],
    [245, '0', '0', 'a', 'Precedes sub n.', 'n', 'Number 3.', 'p', 'Sub n has period not comma.'],
    [245, '0', '0', 'a', 'Precedes sub n.', 'n', 'Number 3,', 'p', 'Sub n has comma.'],
    [245, '0', '0', 'a', 'Precedes sub p.', 'p', 'Sub a has period.'],
    [245, '0', '0', 'a', 'Precedes sub p', 'p', 'Sub a has no period.'],
    [245, '0', '0', 'a', 'The article.'],
    [245, '0', '4', 'a', 'The article.'],
    [245, '0', '2', 'a', 'An article.'],
    [245, '0', '0', 'a', "L\'article."],
    [245, '0', '2', 'a', 'A la mode.'],
    [245, '0', '5', 'a', 'The "quoted article".'],
    [245, '0', '5', 'a', 'The (parenthetical article).'],
    [245, '0', '6', 'a', '(The) article in parentheses).'],
    [245, '0', '9', 'a', "\"(The)\" \'article\' in quotes and parentheses)."],
    [245, '0', '5', 'a', '[The supplied title].'],


);

my @expected = (
    q{245: Must have a subfield _a.},
    q{245: First subfield must be _a, but it is _b},
    q{245: Must end with . (period).},
    q{245: MARC21 allows ? or ! as final punctuation but LCRI 1.0C, Nov. 2003 (LCPS 1.7.1 for RDA records), requires period.},
    q{245: MARC21 allows ? or ! as final punctuation but LCRI 1.0C, Nov. 2003 (LCPS 1.7.1 for RDA records), requires period.},
    q{245: Subfield _c must be preceded by /},
    q{245: Subfield _c must be preceded by /},
    q{245: Subfield _c initials should not have a space.},
    q{245: Subfield _b should be preceded by space-colon, space-semicolon, or space-equals sign.},
    q{245: Subfield _b should be preceded by space-colon, space-semicolon, or space-equals sign.},
    q{245: Subfield _b should be preceded by space-colon, space-semicolon, or space-equals sign.},
    q{245: Subfield _b should be preceded by space-colon, space-semicolon, or space-equals sign.},
    q{245: Subfield _h should not be preceded by space.},
    q{245: Subfield _h must have matching square brackets, h.},
    q{245: Subfield _n must be preceded by . (period).},
    q{245: Subfield _p must be preceded by , (comma) when it follows subfield _n.},
    q{245: Subfield _p must be preceded by . (period) when it follows a subfield other than _n.},
    q{245: First word, the, may be an article, check 2nd indicator (0).},
    q{245: First word, an, may be an article, check 2nd indicator (2).},
    q{245: First word, l, may be an article, check 2nd indicator (0).},
    q{245: First word, a, does not appear to be an article, check 2nd indicator (2).},
);

foreach my $field (@fields) {
    my $field_object = MARC::Field->new( @$field );
    isa_ok( $field_object, 'MARC::Field', 'MARC field' );

    $lint->check_245( $field_object );
    my @warnings = $lint->warnings;
    $lint->clear_warnings();
    while ( @warnings ) {
        my $expected = shift @expected;
        my $actual = shift @warnings;

        is( $actual, $expected, join "\n", ( "Checking expected messages, $expected", $field_object->as_string() ));
    }
} #foreach field

is( scalar @expected, 0, "All expected messages exhausted." );
