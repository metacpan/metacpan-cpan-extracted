#!/usr/bin/env perl
use warnings;
use strict;
use JSON::Create;
no utf8;
my $jc = JSON::Create->new ();
my $in = '赤ブöＡↂϪ';
print $jc->run ($in), "\n";
$jc->unicode_escape_all (1);
print $jc->run ($in), "\n";
$jc->unicode_upper (1);
print $jc->run ($in), "\n";
$jc->unicode_escape_all (0);
print $jc->run ($in), "\n";
