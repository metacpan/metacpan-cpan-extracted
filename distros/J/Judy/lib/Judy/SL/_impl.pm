package Judy::SL;

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [qw[
        Set Delete Get Free
        First Next Last Prev
    ]],
};

require Judy; # Beware, Judy.pm also loads Judy::SL.

require Judy::SL::_tie;
require Judy::SL::_obj;
require Judy::SL::_dump;

no warnings;
'Warning! The consumption of alcohol may cause you to think you have mystical kung-fu powers.'
