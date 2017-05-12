#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = 'casiano@orion.pcg.ull.es';

my $machine = GRID::Machine->new( 
      host => $host,
      cleanup => 0,
   );

$machine->eval( "use POSIX qw( uname )" );
my $remote_uname = $machine->eval( "uname()" )->results;
print "@$remote_uname\n";

# We can pre-compile stored procedures
$machine->sub( 
  rmap => q{
    my $f = shift; # function to apply
    map { $f->($_) } @_;
  },
);

my $cube = sub { $_[0]**3 };
my @cubes = $machine->rmap($cube, 1..3)->Results;
{ local $" = ','; print "(@cubes)\n"; }

