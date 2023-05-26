#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use MARC::Convert::Wikidata::Object::Publisher;

my $obj = MARC::Convert::Wikidata::Object::Publisher->new(
        'name' => 'Academia',
        'place' => 'Praha',
);

p $obj;

# Output:
# MARC::Convert::Wikidata::Object::Publisher  {
#     Parents       Mo::Object
#     public methods (4) : can (UNIVERSAL), DOES (UNIVERSAL), isa (UNIVERSAL), VERSION (UNIVERSAL)
#     private methods (1) : __ANON__ (Mo::is)
#     internals: {
#         name    "Academia",
#         place   "Praha"
#     }
# }