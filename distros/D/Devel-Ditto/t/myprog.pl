#!/usr/bin/env perl

use strict;
use warnings;

use lib qw( t/lib );
use MyPrinter;

print "This is regular text\n";
warn "This is a warning\n";
my $p = MyPrinter->new;
$p->blurt( "Hello, World\n" );
$p->blub( "Whappen?\n" );

# vim:ts=2:sw=2:sts=2:et:ft=perl

