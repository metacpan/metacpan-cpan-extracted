
require 5;
# Time-stamp: "2005-01-05 17:02:40 AST"
# Summary of the ENV.

use Test;
use strict;
BEGIN {plan tests => 2};

ok 1;

my( %e ) = ( %ENV );

$e{"\neee"} = chr(345). q{"!};

print "# \%ENV:\n";
foreach my $x (sort {lc($a) cmp lc($b)} keys %e) {
  my($k,$v) = ($x, $e{$x});
  $v = '*undef*' unless defined $v;
  for my $q ($k,$v) {
   $q =~
   s{([^\x20\x21\x23\x27-\x3F\x41-\x5B\x5D-\x7E])}
    {ord($1) < 256 ? sprintf('\\x%02x', ord($1)) : sprintf('\\x{%0x}', ord($1))}eg;
   $q =~ s/(\\x0a)/$1"\n#\t. "/g;
  }

  print qq{#   "$k" => "$v",\n};
}

ok 1;
