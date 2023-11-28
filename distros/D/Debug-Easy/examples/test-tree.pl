#!/usr/bin/perl

# This script demonstrates how Debug::Easy automatically indents output
# depending on where it is called from in the code.  Here it uses the
# Pseudo module "X1::X2" to nest further levels beyond main subroutines.

use strict;

use lib '.';
use Debug::Easy;
use X1::X2;

my $D = Debug::Easy->new('LogLevel' => 'DEBUGMAX', 'Color' => 1, 'CPADDING' => -25);

$D->DEBUGMAX(['First a local message']);
firstlevel();
secondlevel();

sub firstlevel {
    $D->DEBUG(['First level']);
    secondlevel();
}

sub secondlevel {
    $D->INFO(['Second level']);
    X1::X2::thirdlevel($D);
}
