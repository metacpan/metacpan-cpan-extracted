#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use MARC::Convert::Wikidata::Object::ExternalId;
use MARC::Convert::Wikidata::Object::People;
use Unicode::UTF8 qw(decode_utf8);

my $obj = MARC::Convert::Wikidata::Object::People->new(
        'date_of_birth' => '1952-12-08',
        'external_ids' => [
                MARC::Convert::Wikidata::Object::ExternalId->new(
                        'name' => 'nkcr_aut',
                        'value' => 'jn20000401266',
                ),
        ],
        'name' => decode_utf8('Jiří'),
        'surname' => 'Jurok',
);

p $obj;

# Output:
# MARC::Convert::Wikidata::Object::People  {
#     parents: Mo::Object
#     public methods (4):
#         BUILD
#         Mo::utils:
#             check_array_object
#         Mo::utils::Date:
#             check_date, check_date_order
#     private methods (0)
#     internals: {
#         date_of_birth   "1952-12-08" (dualvar: 1952),
#         external_ids    [
#             [0] MARC::Convert::Wikidata::Object::ExternalId
#         ],
#         name            "Jiří",
#         surname         "Jurok"
#     }
# }