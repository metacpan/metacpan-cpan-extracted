#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = shift || $ENV{GRID_REMOTE_MACHINE};
my $m = GRID::Machine->new( host => $machine );

my $r = $m->eval( q{print STDERR "This is the end\n" });

print "print to STDERR:\n";
print "<".$r->ok.">\n";
print "<".$r->noerr.">\n";

$r = $m->eval( q{warn "This is a warning\n" });

print "Warn:\n";
print "<".$r->ok.">\n";
print "<".$r->noerr.">\n";
