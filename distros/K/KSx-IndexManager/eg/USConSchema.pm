# this is taken directly from the KinoSearch-0.20_04 sample directory without
# changes -- hdp, 2007-07-01

use strict;
use warnings;

package USConSchema::UnIndexedField;
use base 'KinoSearch::Schema::FieldSpec';
sub indexed {0}

package USConSchema;
use base 'KinoSearch::Schema';
use KinoSearch::Analysis::PolyAnalyzer;

our %fields = (
    title   => 'KinoSearch::Schema::FieldSpec',
    content => 'KinoSearch::Schema::FieldSpec',
    url     => 'USConSchema::UnIndexedField',
);

sub analyzer {
    return KinoSearch::Analysis::PolyAnalyzer->new( language => 'en' );
}

1;
