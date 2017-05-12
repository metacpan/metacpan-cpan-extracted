package Enbld::Command::Usage;

use strict;
use warnings;

use 5.010001;

use parent qw/Enbld::Command/;

sub do {
    say "try 'enblder help' for more information.";
}

1;
