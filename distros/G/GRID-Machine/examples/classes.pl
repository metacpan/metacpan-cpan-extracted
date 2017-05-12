#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my @m = qw(orion beowulf);

my $m = GRID::Machine->new( host => shift @m, uses => [qw(Sys::Hostname)]);
print ref($m)."\n";

$m->sub( one => q { print hostname().": one\n"; } );
print $m->one;

my $p = GRID::Machine->new( host => shift @m,  uses => [qw(Sys::Hostname)] );
print ref($p)."\n";

$p->sub( one => q { print hostname().": 1\n"; } );
print $p->one;
