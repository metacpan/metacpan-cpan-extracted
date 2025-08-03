#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use MARC::Convert::Wikidata::Object;
use MARC::Convert::Wikidata::Object::ExternalId;
use MARC::Convert::Wikidata::Object::ISBN;
use MARC::Convert::Wikidata::Object::People;
use MARC::Convert::Wikidata::Object::Publisher;
use MARC::Convert::Wikidata::Object::Work;
use Unicode::UTF8 qw(decode_utf8);

my $aut = MARC::Convert::Wikidata::Object::People->new(
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

my $publisher = MARC::Convert::Wikidata::Object::Publisher->new(
        'name' => decode_utf8('Město Příbor'),
        'place' => decode_utf8('Příbor'),
);

my $isbn = MARC::Convert::Wikidata::Object::ISBN->new(
        'isbn' => '80-238-9541-9',
        'publisher' => $publisher,
);

my $obj = MARC::Convert::Wikidata::Object->new(
        'authors' => [$aut],
        'date_of_publication' => 2002,
        'edition_number' => 2,
        'edition_of_work' => MARC::Convert::Wikidata::Object::Work->new(
                'title' => decode_utf8('Dějiny města Příbora'),
                'title_language' => 'cze',
        ),
        'external_ids' => [
                MARC::Convert::Wikidata::Object::ExternalId->new(
                        'name' => 'cnb',
                        'value' => 'cnb001188266',
                ),
                MARC::Convert::Wikidata::Object::ExternalId->new(
                        'name' => 'lccn',
                        'value' => '53860313',
                ),
        ],
        'isbns' => [$isbn],
        'number_of_pages' => 414,
        'publishers' => [$publisher],
        'title' => decode_utf8('Dějiny města Příbora'),
);

p $obj;

# Output:
# MARC::Convert::Wikidata::Object  {
#     parents: Mo::Object
#     public methods (9):
#         BUILD, full_name
#         Error::Pure:
#             err
#         List::Util:
#             none
#         Mo::utils:
#             check_isa, check_number
#         Mo::utils::Array:
#             check_array, check_array_object
#         Readonly:
#             Readonly
#     private methods (0)
#     internals: {
#         authors               [
#             [0] MARC::Convert::Wikidata::Object::People
#         ],
#         covers                [],
#         date_of_publication   2002,
#         edition_number        2,
#         edition_of_work       MARC::Convert::Wikidata::Object::Work,
#         external_ids          [
#             [0] MARC::Convert::Wikidata::Object::ExternalId,
#             [1] MARC::Convert::Wikidata::Object::ExternalId
#         ],
#         isbns                 [
#             [0] MARC::Convert::Wikidata::Object::ISBN
#         ],
#         number_of_pages       414,
#         publishers            [
#             [0] MARC::Convert::Wikidata::Object::Publisher
#         ],
#         title                 "Dějiny města Příbora"
#     }
# }