#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More 'no_plan';
use Doit;
use Doit::Guarded; # imports ensure + using

my $d = Doit->init;
$d->add_component('guarded');

{
    my $var = 0;
    my $called = 0;

    $d->guarded_step(
	"var to zero",
	ensure { $var == 1 }
	using  { $var = 1; $called++  }
    );
    is $var, 1;
    is $called, 1, '1st time "using" called';
}
