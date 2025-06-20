#!/usr/bin/env perl

use strict;
use warnings;

use MARC::Field008;
use MARC::Leader;
use Data::Printer;

# Object.
my $leader = MARC::Leader->new->parse('     nam a22        4500');
my $obj = MARC::Field008->new(
        'leader' => $leader,
);

# Parse.
my $data = $obj->parse('830304s1982    xr a         u0|0 | cze  ');

# Dump.
p $data;

# Output:
# Data::MARC::Field008  {
#     parents: Mo::Object
#     public methods (13):
#         BUILD
#         Data::MARC::Field008::Utils:
#             check_cataloging_source, check_date, check_modified_record, check_type_of_date
#         Error::Pure:
#             err
#         Error::Pure::Utils:
#             err_get
#         Mo::utils:
#             check_isa, check_length_fix, check_number, check_required, check_strings
#         Readonly:
#             Readonly
#     private methods (0)
#     internals: {
#         cataloging_source      " ",
#         date_entered_on_file   830304,
#         date1                  1982,
#         date2                  "    ",
#         language               "cze",
#         material               Data::MARC::Field008::Book,
#         material_type          "book",
#         modified_record        " ",
#         place_of_publication   "xr ",
#         raw                    "830304s1982    xr a         u0|0 | cze  " (dualvar: 830304),
#         type_of_date           "s"
#     }
# }