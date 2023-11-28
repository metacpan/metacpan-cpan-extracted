#!/usr/bin/env perl

use strict;
use warnings;

use Data::MARC::Leader;
use MARC::Leader::Print;

# Print object.
my $print = MARC::Leader::Print->new;

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
# Record status: Corrected or revised
# Type of record: Cartographic material
# Bibliographic level: Monograph/Item
# Type of control: No specified type
# Character coding scheme: UCS/Unicode
# Indicator count: Number of character positions used for indicators
# Subfield code count: Number of character positions used for a subfield code (2)
# Base address of data: 541
# Encoding level: Full level
# Descriptive cataloging form: ISBD punctuation included
# Multipart resource record level: Not specified or not applicable
# Length of the length-of-field portion: Number of characters in the length-of-field portion of a Directory entry (4)
# Length of the starting-character-position portion: Number of characters in the starting-character-position portion of a Directory entry (5)
# Length of the implementation-defined portion: Number of characters in the implementation-defined portion of a Directory entry (0)
# Undefined: Undefined