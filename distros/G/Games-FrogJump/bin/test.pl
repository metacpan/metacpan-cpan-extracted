use 5.012;
use Term::ANSIColor;
use strict;
use warnings;
$| = 0;
print $|;
package x
{
    our $| = 2;
    print $|;
}
print $|;
