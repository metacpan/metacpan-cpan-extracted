#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use HTML::Make::Calendar 'calendar';
my $cal = calendar ();
print $cal->text ();
my $oldcal = calendar (year => 1966, month => 3);
print $oldcal->text ();

