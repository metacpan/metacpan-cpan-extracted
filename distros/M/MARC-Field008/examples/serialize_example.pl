#!/usr/bin/env perl

use strict;
use warnings;

use MARC::Field008;
use MARC::Leader;
use Data::MARC::Field008;
use Data::MARC::Field008::Book;

# Object.
my $leader = MARC::Leader->new->parse('     nam a22        4500');
my $obj = MARC::Field008->new(
        'leader' => $leader,
);

# Data.
my $material = Data::MARC::Field008::Book->new(
        'biography' => ' ',
        'conference_publication' => '0',
        'festschrift' => '0',
        'form_of_item' => 'r',
        'government_publication' => ' ',
        'illustrations' => '    ',
        'index' => '0',
        'literary_form' => '0',
        'nature_of_content' => '    ',
        'target_audience' => ' ',
);
my $data = Data::MARC::Field008->new(
        'cataloging_source' => ' ',
        'date_entered_on_file' => '      ',
        'date1' => '    ',
        'date2' => '    ',
        'language' => 'cze',
        'material' => $material,
        'material_type' => 'book',
        'modified_record' => ' ',
        'place_of_publication' => '   ',
        'type_of_date' => 's',
);

# Serialize.
print "'".$obj->serialize($data)."'\n";

# Output:
# '      s                r     000 0 cze  '