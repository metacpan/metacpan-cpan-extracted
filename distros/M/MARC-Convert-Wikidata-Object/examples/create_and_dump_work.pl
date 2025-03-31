#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use MARC::Convert::Wikidata::Object::ExternalId;
use MARC::Convert::Wikidata::Object::People;
use MARC::Convert::Wikidata::Object::Work;
use Unicode::UTF8 qw(decode_utf8);

my $obj = MARC::Convert::Wikidata::Object::Work->new(
        'author' => MARC::Convert::Wikidata::Object::People->new(
                'name' => decode_utf8('Tomáš Garrigue'),
                'surname' => 'Masaryk',
        ),
        'external_ids' => [
                MARC::Convert::Wikidata::Object::ExternalId->new(
                        'name' => 'nkcr_aut',
                        'value' => 'jn20000401266',
                ),
        ],
        'title' => decode_utf8('O ethice a alkoholismu'),
        'title_language' => 'cze',
);

p $obj;

# Output:
# MARC::Convert::Wikidata::Object::Work  {
#     parents: Mo::Object
#     public methods (3):
#         BUILD
#         Mo::utils:
#             check_array_object, check_isa
#     private methods (0)
#     internals: {
#         author           MARC::Convert::Wikidata::Object::People,
#         external_ids     [
#             [0] MARC::Convert::Wikidata::Object::ExternalId
#         ],
#         title            "O ethice a alkoholismu",
#         title_language   "cze"
#     }
# }