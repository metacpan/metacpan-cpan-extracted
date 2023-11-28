#!/usr/bin/env perl

use strict;
use warnings;

use Data::MARC::Leader;
use MARC::Leader;

# Object.
my $obj = MARC::Leader->new;

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

# Serialize.
my $leader = $obj->serialize($data_marc_leader);

# Print to output.
print $leader."\n";

# Output:
# 02200cem a2200541 i 4500