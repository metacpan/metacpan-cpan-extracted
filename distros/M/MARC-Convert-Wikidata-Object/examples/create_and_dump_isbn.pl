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
#     parents: Mo::Object
#     public methods (8):
#         BUILD, type
#         Error::Pure:
#             err
#         List::Util:
#             none
#         Mo::utils:
#             check_bool, check_isa, check_required
#         Readonly:
#             Readonly
#     private methods (0)
#     internals: {
#         _isbn        978-80-00-05046-1 (Business::ISBN13),
#         collective   0,
#         isbn         "978-80-00-05046-1" (dualvar: 978),
#         publisher    MARC::Convert::Wikidata::Object::Publisher
#     }
# }