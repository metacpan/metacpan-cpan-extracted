package Devel::Monitor::TestArray;
use Tie::Array;
use base 'Tie::StdArray';

use Devel::Monitor::Common qw(:all);
 
sub DESTROY { printMsg "Devel::Monitor::TestArray::DESTROY : $_[0]\n"; }
 
1;