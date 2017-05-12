#!/usr/bin/perl
use strict;
use GRID::Machine;
use Sys::Hostname;

sub usage {
  warn "Usage:\n$0 host[:port] #number\n";
  exit(1);
}

my $hostport = shift || $ENV{GRID_REMOTE_MACHINE} || usage();
$hostport =~ m{^([\w.]+)(?::(\d+))?$} or usage();
my $host = $1 || 'localhost';
my $port = $2 || 0;

my $machine = GRID::Machine->new( 
  host => $host, 
  debug => $port,
  uses => [ 'Sys::Hostname' ] 
);

my $r = $machine->sub( 
  fact => q{
    my $x = shift;

    #$DB::single = 1;
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

      #$DB::single = 1;
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

my $n = shift || usage();

$r = $machine->fact($n);

die $r->errmsg unless $r->ok;
print "=============\nfact($n) is ".$r->result."\n";

