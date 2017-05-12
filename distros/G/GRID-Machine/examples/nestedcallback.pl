#!/usr/bin/perl
use strict;
use GRID::Machine;
use Sys::Hostname;

my $host = $ENV{GRID_REMOTE_MACHINE};

my $machine = GRID::Machine->new( host => $host, uses => [ 'Sys::Hostname' ] );

my $r = $machine->sub( 
  fact => q{
    my $x = shift;

    gprint &hostname . ": fact($x)\n";

    if ($x > 1) {
      my $r = localfact($x-1);
      return $x*$r;
    }
    else {
      return 1;
    }
  } 
);
die $r->errmsg unless $r->ok;

$r = $machine->callback( 

    localfact => sub {
      my $x = shift;

      print &hostname . ": fact($x)\n";

      if ($x > 1) {
        my $r = $machine->fact($x-1)->result;
        return $x*$r;
      }
      else {
        return 1;
      }

    } 

);
die $r->errmsg unless $r->ok;

my $n = shift;

$r = $machine->fact($n);

die $r->errmsg unless $r->ok;
print "=============\nfact($n) is ".$r->result."\n";

