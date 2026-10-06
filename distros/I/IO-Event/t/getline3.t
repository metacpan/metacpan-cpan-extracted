#!/usr/bin/perl -I.

use strict;
use warnings;

eval { require AnyEvent::Impl::Perl; require AnyEvent; };  ## no critic (Community::DiscouragedModules)
if ($@) {
    print "1..0 # Skip AnyEvent not installed\n";
    exit 0;
}
use IO::Event;
IO::Event->import('AnyEvent');
require './t/getline.tt';

