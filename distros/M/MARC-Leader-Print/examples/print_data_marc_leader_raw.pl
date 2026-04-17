#!/usr/bin/env perl

use strict;
use warnings;

use Data::MARC::Leader;
use MARC::Leader::Print;
use Unicode::UTF8 qw(encode_utf8);

# Print object.
my $print = MARC::Leader::Print->new(
        'lang' => 'cs',
        'mode_desc' => 0,
);

# Data object.
my $data_marc_leader = Data::MARC::Leader->new(
        'bibliographic_level' => 'm',
        'char_coding_scheme' => 'a',
        'data_base_addr' => 541,
        'descriptive_cataloging_form' => 'i',
        'encoding_level' => ' ',
        'impl_def_portion_len' => '0',
        'indicator_count' => '2',
        'length' => 2200,
        'length_of_field_portion_len' => '4',
        'multipart_resource_record_level' => ' ',
        'starting_char_pos_portion_len' => '5',
        'status' => 'c',
        'subfield_code_count' => '2',
        'type' => 'e',
        'type_of_control' => ' ',
        'undefined' => '0',
);

# Print to output.
print encode_utf8(scalar $print->print($data_marc_leader)), "\n";

# Output:
# Délka záznamu: 2200
# Status záznamu: c
# Typ záznamu: e
# Bibliografická úroveň: m
# Typ kontroly:  
# Použitá znaková sada: a
# Délka indikátorů: 2
# Délka označení podpole: 2
# Bázová adresa údajů: 541
# Úroveň úplnosti záznamu:  
# Forma katalogizačního popisu: i
# Úroveň záznamu vícedílného zdroje:  
# Počet znaků délky pole: 4
# Délka počáteční znakové pozice: 5
# Délka implementačně definované části: 0
# Není definován: 0