#!perl
use strict;
use warnings;
use FixerIO::API;
use DDP hash_max=>5; # provides 'p' to print data dump

my $access_key = '7497f332bb7b25ecfc14efb5cbd170ab';
my $fixer = FixerIO::API->new( $access_key );

# get latest data
my $ld = $fixer->latest;

p $ld, as=>"\nLatest Data:";

# Latest Data:
# {
#     success     1 (JSON::PP::Boolean),
#     base        "EUR",
#     date        "2023-09-03" (dualvar: 2023),
#     timestamp   1693764783,
#     rates       {
#         AED   3.965325,
#         AFN   79.575894,
#         ALL   108.330797,
#         AMD   418.325847,
#         ANG   1.954454,
#         (...skipping 165 keys...)
#     }
# }
