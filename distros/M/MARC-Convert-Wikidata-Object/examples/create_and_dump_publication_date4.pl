#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use MARC::Convert::Wikidata::Object::PublicationDate;

my $obj = MARC::Convert::Wikidata::Object::PublicationDate->new(
        'date' => '2014',
        'sourcing_circumstances' => 'circa',
);

p $obj;

# Output:
# MARC::Convert::Wikidata::Object::PublicationDate  {
#     parents: Mo::Object
#     public methods (5):
#         BUILD
#         Error::Pure:
#             err
#         Mo::utils:
#             check_bool, check_strings
#         Readonly:
#             Readonly
#     private methods (1): _check_conflict
#     internals: {
#         date                     2014,
#         sourcing_circumstances   "circa"
#     }
# }