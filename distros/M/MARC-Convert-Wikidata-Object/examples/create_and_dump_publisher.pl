#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use MARC::Convert::Wikidata::Object::ExternalId;
use MARC::Convert::Wikidata::Object::Publisher;

my $obj = MARC::Convert::Wikidata::Object::Publisher->new(
        'external_ids' => [
                MARC::Convert::Wikidata::Object::ExternalId->new(
                        'name' => 'nkcr_aut',
                        'value' => 'ko2002101950',
                ),
        ],
        'id' => '000010003',
        'name' => 'Academia',
        'place' => 'Praha',
);

p $obj;

# Output:
# MARC::Convert::Wikidata::Object::Publisher  {
#     parents: Mo::Object
#     public methods (3):
#         BUILD
#         Mo::utils:
#             check_required
#         Mo::utils::Array:
#             check_array_object
#     private methods (0)
#     internals: {
#         external_ids   [
#             [0] MARC::Convert::Wikidata::Object::ExternalId
#         ],
#         id             "000010003" (dualvar: 10003),
#         name           "Academia",
#         place          "Praha"
#     }
# }