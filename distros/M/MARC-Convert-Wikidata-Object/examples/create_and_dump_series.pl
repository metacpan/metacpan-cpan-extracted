#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use MARC::Convert::Wikidata::Object::Publisher;
use MARC::Convert::Wikidata::Object::Series;
use Unicode::UTF8 qw(decode_utf8);

my $obj = MARC::Convert::Wikidata::Object::Series->new(
        'name' => decode_utf8('Malé encyklopedie'),
        'publisher' => MARC::Convert::Wikidata::Object::Publisher->new(
                'name' => decode_utf8('Mladá Fronta'),
        ),
        'series_ordinal' => 5,
);

p $obj;

# Output:
# MARC::Convert::Wikidata::Object::Series  {
#     Parents       Mo::Object
#     public methods (6) : BUILD, can (UNIVERSAL), DOES (UNIVERSAL), check_required (Mo::utils), isa (UNIVERSAL), VERSION (UNIVERSAL)
#     private methods (1) : __ANON__ (Mo::is)
#     internals: {
#         name             "Mal� encyklopedie",
#         publisher        MARC::Convert::Wikidata::Object::Publisher,
#         series_ordinal   5
#     }
# }