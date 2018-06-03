package FLAT::GFA;

use parent FLAT::FA;

#-- will implement DFA->RE conversions using GFA method
#-- .. one key detail here is that transitions are no longer symbols, but become regular expressions themselves

1;
