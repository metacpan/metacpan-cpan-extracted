#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use MARC::Convert::Wikidata::Object::People;
use Unicode::UTF8 qw(decode_utf8);

my $obj = MARC::Convert::Wikidata::Object::People->new(
        'date_of_birth' => '1952-12-08',
        'name' => decode_utf8('Jiří'),
        'nkcr_aut' => 'jn20000401266',
        'surname' => 'Jurok',
);

p $obj;

# Output:
# MARC::Convert::Wikidata::Object::People  {
#     Parents       Mo::Object
#     public methods (7) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), err (Error::Pure), check_date (Mo::utils::Date), isa (UNIVERSAL), VERSION (UNIVERSAL)
#     private methods (1) : __ANON__ (Mo::build)
#     internals: {
#         date_of_birth   "1952-12-08",
#         name            "Jiří",
#         nkcr_aut        "jn20000401266",
#         surname         "Jurok"
#     }
# }