#!/usr/bin/env perl

use strict;
use warnings;

use Data::MARC::Field008;
use Data::MARC::Field008::Book;
use MARC::Field008::Print;
use Unicode::UTF8 qw(encode_utf8);

# Print object.
my $print = MARC::Field008::Print->new(
        'lang' => 'cs',
        'mode_desc' => 0,
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
print encode_utf8(scalar $print->print($data_marc_field008)), "\n";

# Output:
# Datum uložení do souboru: 830304
# Typ data/publikační status: s
# Datum 1: 1982
# Datum 2:     
# Místo vydání, produkce nebo realizace: xr 
# Materiál: book
# Ilustrace: a
# Uživatelské určení:  
# Forma popisné jednotky:  
# Povaha obsahu: 
# Vládní publikace: u
# Publikace z konference: 0
# Jubilejní sborník: |
# Rejstřík: 0
# Literární forma: |
# Biografie:  
# Jazyk dokumentu: cze
# Modifikace záznamu:  
# Zdroj katalogizace: