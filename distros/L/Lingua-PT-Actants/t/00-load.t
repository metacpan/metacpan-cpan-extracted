#!perl -T

use Test::More tests => 1;

BEGIN {
  foreach (qw/Lingua::PT::Actants/) {
    use_ok($_) || print "$_ failed to load!\n";
  }
}
