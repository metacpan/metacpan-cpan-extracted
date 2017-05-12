#!/usr/bin/perl -w
use strict;
use GRID::Machine;
use Sys::Hostname;

# This program has errors
#
my $host = 'beowulf';

sub Titi::test_callback {
  print 'Inside test_callback() host: ' . &hostname . "\n";
  return 'ret from local callback'
} 

my $machine = GRID::Machine->new(
    host => $host,
    uses => [ 'Sys::Hostname' ]
);

my $r = $machine->sub( remote => q{
    gprint hostname().": inside remote\n";
    Titi::test_callback();
} );
die $r->errmsg unless $r->ok;

$r = $machine->callback( 'Titi::test_callback' );
die $r->errmsg unless $r->ok;

$r = $machine->remote();

die $r->errmsg unless $r->ok;
die $r->errmsg if $r->errmsg; # workaround!

#pp2@nereida:~/LGRID_Machine/examples$ callbackbyname_err1.pl
#beowulf: inside remote
#beowulf: Error running sub remote: Undefined subroutine &Titi::test_callback called at (eval 159) line 3, <STDIN> line 201.
#pp2@nereida:~/LGRID_Machine/examples$

