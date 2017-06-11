#!/usr/bin/env perl
use warnings;
use strict;
use JSON::Create;
my $jc = JSON::Create->new ();
# This type handler returns a non-UTF-8 string.
$jc->type_handler (sub {return '"'. pack ("CCC", 0x99, 0x10, 0x0) . '"';});
use utf8;
# sub {1} triggers the type handler for a code reference, and the ぶー
# contains a "utf8" flag, so this combination sets off the problem.
print $jc->run ({a => sub {1}, b => 'ぶー'});
