#!/usr/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = $ENV{GRID_REMOTE_MACHINE};

my $machine = GRID::Machine->new(
   host => $host, 
   command => ['ssh', '-X', $host, 'perl'], 
);

system('xhost +');
print $machine->eval(q{ 
  print "$ENV{DISPLAY}\n" if $ENV{DISPLAY};
  CORE::system('xclock') and  warn "Mmmm.. something went wrong!";
});

