#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use HTML::Make::Calendar 'calendar';
my $cal = calendar (first => 7);
print $cal->text ();

