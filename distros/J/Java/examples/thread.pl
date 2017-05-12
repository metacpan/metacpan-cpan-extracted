#!/home/markt/bin/perl -w
use strict;
no strict 'subs';
use lib qw(..);
use Java;

my $java = new Java();


my $thread = $java->create_object("java.lang.Thread");
