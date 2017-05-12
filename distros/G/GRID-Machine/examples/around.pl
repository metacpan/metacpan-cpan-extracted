#!/usr/bin/perl -w
use strict;
use GRID::Machine;

my $machine = GRID::Machine->new( host => $ENV{GRID_REMOTE_MACHINE} || shift);

$machine->sub( 
  squares => q{ map { $_*$_ } @_ },
  filter => 'results',
  around => sub { 
              my $self = shift; 
              my $r = $self->call( 'squares', @_ ); 
              map { $_+1 } @$r; 
            }
);

my @x = (3..5);
my @r = $machine->squares(@x);
print "@r\n";
