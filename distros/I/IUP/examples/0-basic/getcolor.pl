# IUP->GetColor example
#
# Creates a predefined color selection dialog which returns the
# selected color in the RGB format.

use strict;
use warnings;

use IUP ':all';

my ($r, $g, $b) = IUP->GetColor(100, 100, 255, 255, 255);

IUP->Message("COLOR: r=$r g=$g b=$b") if $r;
