package Devel::Monitor::TestHash;
use Tie::Hash;
use base 'Tie::StdHash';
 
use Devel::Monitor::Common qw(:all);

sub DESTROY { printMsg "Devel::Monitor::TestHash::DESTROY : $_[0]\n"; }

1;