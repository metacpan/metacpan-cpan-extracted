package Hash::Util::Set;
use strict;
use warnings;

use Exporter qw[import];

BEGIN {
  our $VERSION   = '0.01';
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

  our %EXPORT_TAGS = ( all => \@EXPORT_OK );

  my $use_pp = $ENV{HASH_UTIL_SET_PP};
  if (!$use_pp) {
    eval {
      require Hash::Util::Set::XS;
    };
    $use_pp = !!$@;
  }

  if ($use_pp) {
    require Hash::Util::Set::PP;
    Hash::Util::Set::PP->import(@EXPORT_OK);
    our $IMPLEMENTATION = 'PP';
  }
  else {
    Hash::Util::Set::XS->import(@EXPORT_OK);
    our $IMPLEMENTATION = 'XS';
  }

  *keys_or  = \&keys_union;
  *keys_and = \&keys_intersection;
  *keys_sub = \&keys_difference;
  *keys_xor = \&keys_symmetric_difference;

  push @EXPORT_OK, qw[ keys_or
                       keys_and
                       keys_sub
                       keys_xor ];
}

1;
