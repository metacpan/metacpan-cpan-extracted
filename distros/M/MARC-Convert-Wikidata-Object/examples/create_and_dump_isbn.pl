#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use MARC::Convert::Wikidata::Object::ISBN;
use MARC::Convert::Wikidata::Object::Publisher;

my $obj = MARC::Convert::Wikidata::Object::ISBN->new(
        'isbn' => '978-80-00-05046-1',
        'publisher' => MARC::Convert::Wikidata::Object::Publisher->new(
                'name' => 'Albatros',
        ),
);

p $obj;

# Output:
# MARC::Convert::Wikidata::Object::ISBN  {
#     Parents       Mo::Object
#     public methods (9) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), err (Error::Pure), check_isa (Mo::utils), check_required (Mo::utils), isa (UNIVERSAL), type, VERSION (UNIVERSAL)
#     private methods (1) : __ANON__ (Mo::build)
#     internals: {
#         _isbn       Business::ISBN13,
#         isbn        "978-80-00-05046-1",
#         publisher   MARC::Convert::Wikidata::Object::Publisher
#     }
# }