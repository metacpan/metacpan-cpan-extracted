#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More;
use Doit;

plan 'no_plan';

my $doit = Doit->init;
$doit->add_component('DoitX::Example');
pass 'add_component called on DoitX component';

is $doit->example_hello_world(4711), 42, 'called DoitX::Example function';

__END__
