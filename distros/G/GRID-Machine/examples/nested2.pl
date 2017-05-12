#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;
use Data::Dumper;

my $machine = GRID::Machine->new( 
      host => 'casiano@orion.pcg.ull.es',
      cleanup => 0,
   );

$machine->eval( "use POSIX qw( uname )" );
my $remote_uname = $machine->eval( "uname()" )->results;
print "@$remote_uname\n";

# We can pre-compile stored procedures
$machine->sub( 
  squares => q{
    my @r;
    for my $x (@_) {
       push @r, [ map { $_*$_ } @$x];
    }
    return @r;
  },
);

my $x = [1..3];
my $content = $machine->squares($x,$x,$x)->results;
print Dumper($content);
