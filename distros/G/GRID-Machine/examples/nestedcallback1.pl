#!/usr/bin/perl
use strict;
use GRID::Machine;
use Sys::Hostname;
use Data::Dumper;

my $host = shift || 'beowulf';

my $machine = GRID::Machine->new(
    host => $host,
    uses => [ 'Sys::Hostname' ]
);

my $r = $machine->sub( 
  fact => q{
    my $x = shift;

    print &hostname . ": fact($x)\n";

    if ($x > 1) {
      my ($r) = localfact($x-1);
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

$r = $machine->fact(5);

die $r->errmsg unless $r->ok;
print "fact(5) is ".$r->result."\n";

print Dumper($r);

$r = $machine->fact(4);

die $r->errmsg unless $r->ok;

print "fact(4) is ".$r->result."\n";
