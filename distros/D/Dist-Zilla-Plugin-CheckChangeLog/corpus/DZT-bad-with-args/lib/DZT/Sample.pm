use strict;
use warnings;
package     # hidden from PAUSE
    DZT::Sample;

sub return_arrayref_of_values_passed {
  my $invocant = shift;
  return \@_;
}

1;
