#  Subclass for 'Enumeration' test suite.

use strict;
use warnings;
package SubClass;
use base 'Enumeration';

__PACKAGE__->set_enumerations(qw(this IS a test));
