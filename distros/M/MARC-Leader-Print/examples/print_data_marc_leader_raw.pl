#!/usr/bin/env perl

use strict;
use warnings;

use Data::MARC::Leader;
use MARC::Leader::Print;

# Print object.
my $print = MARC::Leader::Print->new(
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
print scalar $print->print($data_marc_leader), "\n";

# Output:
# Record length: 2200
# Record status: c
# Type of record: e
# Bibliographic level: m
# Type of control:  
# Character coding scheme: a
# Indicator count: 2
# Subfield code count: 2
# Base address of data: 541
# Encoding level:  
# Descriptive cataloging form: i
# Multipart resource record level:  
# Length of the length-of-field portion: 4
# Length of the starting-character-position portion: 5
# Length of the implementation-defined portion: 0
# Undefined: 0