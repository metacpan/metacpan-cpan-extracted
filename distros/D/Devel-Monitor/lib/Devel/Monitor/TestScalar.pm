package Devel::Monitor::TestScalar;
use Tie::Scalar;
use base 'Tie::StdScalar';

use Devel::Monitor::Common qw(:all);

sub DESTROY { printMsg "Devel::Monitor::TestScalar::DESTROY : $_[0]\n"; }
 
1;