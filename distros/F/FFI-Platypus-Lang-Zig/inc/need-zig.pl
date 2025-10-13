use strict;
use warnings;
use File::Which qw( which );

unless(which 'zig')
{
  print "This distribution requires that you have the Zig compiler installed\n";
  exit;
}
