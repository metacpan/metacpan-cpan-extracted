#!/usr/bin/env perl

use strict;
use warnings;

use Data::MARC::Field008;
use Data::MARC::Field008::Book;
use MARC::Field008::Print;

# Print object.
my $print = MARC::Field008::Print->new(
        'lang' => 'en',
);

# Data object.
my $data_marc_field008 = Data::MARC::Field008->new(
        'cataloging_source' => ' ',
        'date_entered_on_file' => '830304',
        'date1' => '1982',
        'date2' => '    ',
        'language' => 'cze',
        'material' => Data::MARC::Field008::Book->new(
                'biography' => ' ',
                'conference_publication' => '0',
                'festschrift' => '|',
                'form_of_item' => ' ',
                'government_publication' => 'u',
                'illustrations' => 'a   ',
                'index' => '0',
                'literary_form' => '|',
                'nature_of_content' => '    ',
                #         89012345678901234
                'raw' => 'a         u0|0 | ',
                'target_audience' => ' ',
        ),
        'material_type' => 'book',
        'modified_record' => ' ',
        'place_of_publication' => 'xr ',
        #         0123456789012345678901234567890123456789
        'raw' => '830304s1982    xr a         u0|0 | cze  ',
        'type_of_date' => 's',
);

# Print to output.
print scalar $print->print($data_marc_field008), "\n";

# Output:
# Date entered on file: 830304
# Type of date/Publication status: Single known date/probable date
# Date 1: 1982
# Date 2:     
# Place of publication, production, or execution: xr 
# Material: book
# Illustrations: Illustrations
# Target audience: Unknown or not specified
# Form of item: None of the following
# Nature of contents: 
# Government publication: Unknown if item is government publication
# Conference publication: Not a conference publication
# Festschrift: No attempt to code
# Index: No index
# Literary form: No attempt to code
# Biography: No biographical material
# Language: cze
# Modified record: Not modified
# Cataloging source: National bibliographic agency