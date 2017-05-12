use strict;
use warnings;
package DZT::Sample;

use Zorch::Wingo::Ploppington;

sub return_arrayref_of_values_passed {
  my $invocant = shift;
  return \@_;
}

1;
