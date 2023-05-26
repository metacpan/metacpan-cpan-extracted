#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use MARC::Convert::Wikidata::Object;
use MARC::Convert::Wikidata::Object::ISBN;
use MARC::Convert::Wikidata::Object::People;
use MARC::Convert::Wikidata::Object::Publisher;
use Unicode::UTF8 qw(decode_utf8);

my $aut = MARC::Convert::Wikidata::Object::People->new(
        'date_of_birth' => '1952-12-08',
        'name' => decode_utf8('Jiří'),
        'nkcr_aut' => 'jn20000401266',
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
        'ccnb' => 'cnb001188266',
        'date_of_publication' => 2002,
        'edition_number' => 2,
        'isbns' => [$isbn],
        'number_of_pages' => 414,
        'publishers' => [$publisher],
);

p $obj;

# Output:
# MARC::Convert::Wikidata::Object  {
#     Parents       Mo::Object
#     public methods (11) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), err (Error::Pure), full_name, check_array (Mo::utils), check_array_object (Mo::utils), isa (UNIVERSAL), none (List::MoreUtils::XS), Readonly (Readonly), VERSION (UNIVERSAL)
#     private methods (1) : __ANON__ (Mo::is)
#     internals: {
#         authors                   [
#             [0] MARC::Convert::Wikidata::Object::People
#         ],
#         authors_of_introduction   [],
#         ccnb                      "cnb001188266",
#         compilers                 [],
#         date_of_publication       2002,
#         edition_number            2,
#         editors                   [],
#         illustrators              [],
#         isbns                     [
#             [0] MARC::Convert::Wikidata::Object::ISBN
#         ],
#         krameriuses               [],
#         number_of_pages           414,
#         publishers                [
#             [0] MARC::Convert::Wikidata::Object::Publisher
#         ],
#         series                    [],
#         translators               []
#     }
# }