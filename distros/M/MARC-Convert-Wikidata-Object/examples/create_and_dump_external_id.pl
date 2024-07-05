#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use MARC::Convert::Wikidata::Object::ExternalId;

my $obj = MARC::Convert::Wikidata::Object::ExternalId->new(
        'name' => 'cnb',
        'value' => 'cnb003597104',
);

p $obj;

# Output:
# MARC::Convert::Wikidata::Object::ExternalId  {
#     parents: Mo::Object
#     public methods (3):
#         BUILD
#         Mo::utils:
#             check_bool, check_required
#     private methods (0)
#     internals: {
#         deprecated   0,
#         name         "cnb",
#         value        "cnb003597104"
#     }
# }