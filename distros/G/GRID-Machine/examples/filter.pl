#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;
use Data::Dumper;

my $machine = GRID::Machine->new( host => $ENV{GRID_REMOTE_MACHINE} || shift);

$machine->sub( 
  nofilter => q{ map { $_*$_ } @_ },
);

$machine->sub( 
  filter_results => q{ map { $_*$_ } @_ },
  filter => 'results'
);

$machine->sub( 
  filter_result => q{ map { $_*$_ } @_ },
  filter => 'result',
);

my @x = (3..5);
my $content = $machine->nofilter(@x);
print Dumper($content);

$content = $machine->filter_results(@x);
print Dumper($content);

$content = $machine->filter_result(@x);
print Dumper($content);

