#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = GRID::Machine->new(
                   host => shift() || $ENV{GRID_REMOTE_MACHINE}, 
                   uses => [ 'Sys::Hostname' ]
              );

$machine->sub( iguales => q{
    my $first = [1..3];
    my $sec = $first;

    return (hostname(), $first, $sec);
  },
);

my ($h, $f, $s)  = $machine->iguales->Results;
print "$h: same\n" if $f == $s;
print "$h: different\n" if $f != $s;
