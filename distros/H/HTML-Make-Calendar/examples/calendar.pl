#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use HTML::Make::Calendar 'calendar';
my $out = calendar (year => 2021, month => 1);
print $out->text ();
