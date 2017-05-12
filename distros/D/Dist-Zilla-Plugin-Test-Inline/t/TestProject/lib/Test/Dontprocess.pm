use strict;
use warnings;
package Test::Dontprocess;
 
=begin testing

use Test::Simple => 1;
ok(1 != 2, "1 does not equal 2");

=end testing

=cut
sub some_function {
  return shift;
}
 
1;