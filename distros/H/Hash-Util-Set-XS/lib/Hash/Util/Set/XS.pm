package Hash::Util::Set::XS;
use strict;
use warnings;

use Exporter qw[import];

our @EXPORT_OK = qw[ keys_union
                     keys_intersection
                     keys_difference
                     keys_symmetric_difference
                     keys_disjoint
                     keys_equal
                     keys_subset
                     keys_proper_subset
                     keys_superset
                     keys_proper_superset
                     keys_any
                     keys_all
                     keys_none ];

BEGIN {
  our $VERSION = '0.02';
  require XSLoader; XSLoader::load(__PACKAGE__, $VERSION);
}

1;
