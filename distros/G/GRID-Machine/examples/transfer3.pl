#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = shift || 'casiano@orion.pcg.ull.es';

my $machine = GRID::Machine->new( host => $host );
my $DOC = << "DOC";
one. two. three.  
four. five. six. 
seven.
DOC

# List context: returns  a list with the lines
{
  local $/ = '.';
  my @a = $machine->qx("echo '$DOC'");
  local $"= ",";
  print "@a";
}

# scalar context: returns a string with the output
my $a = $machine->qx("echo '$DOC'");
print $a;
