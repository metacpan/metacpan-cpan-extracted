#
# This file is part of Dist-Zilla-Plugin-RemovePrereqsMatching
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;
package DZT::Sample;

sub return_arrayref_of_values_passed {
  my $invocant = shift;
  return \@_;
}

1;
