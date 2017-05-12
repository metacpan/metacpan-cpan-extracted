package Judy::L;

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [qw[
        Set Delete Get Free
        First      Next      Last      Prev
        FirstEmpty NextEmpty LastEmpty PrevEmpty
        MemUsed Count Nth
    ]],
};

require Judy; # Beware, Judy.pm also loads Judy::L.

require Judy::L::_tie;
require Judy::L::_obj;

no warnings;
'Warning! The consumption of alcohol may cause you to think you have mystical kung-fu powers.'
