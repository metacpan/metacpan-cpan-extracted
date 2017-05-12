#!/usr/local/bin/perl -w

# Version: $Id: empty_changer.t 3 2007-10-05 15:49:42Z sergey.chernyshev $

use strict;
use Test;
BEGIN { plan tests => 3}

print "Testing if module exists ... \n";
use HTML::LinkChanger;
ok(1);

print "Testing if new object can be created without any parameters ... \n";
my $changer = new HTML::LinkChanger();
ok($changer);

my $in = '<a href="http://www.google.com/"><img src="/image.gif"></a>';

print "Testing if input is returned as is if no filters supplied ... \n";

ok($changer->filter($in), $in);

