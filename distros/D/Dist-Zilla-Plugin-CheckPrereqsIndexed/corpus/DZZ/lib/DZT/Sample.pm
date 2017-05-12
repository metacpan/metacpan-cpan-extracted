use strict;
use warnings;
package DZT::Sample;

use Dist::Zilla;

sub return_arrayref_of_values_passed {
  my $invocant = shift;
  return \@_;
}

1;
