#!/usr/bin/perl -w
use strict;
use GRID::Machine;
use Sys::Hostname;

my $host = $ENV{GRID_REMOTE_MACHINE};

sub Tutu::test_callback {
  print 'Inside test_callback() host: ' . &hostname . "\n";
  return 3.1415;
} 

my $machine = GRID::Machine->new(host => $host, uses => [ 'Sys::Hostname' ]);

my $r = $machine->sub( remote => q{
    gprint hostname().": inside remote\n";

    my $r = test_callback(); # scalar context

    gprint hostname().": returned value from callback: $r\n";
} );
die $r->errmsg unless $r->ok;

$r = $machine->callback( 'Tutu::test_callback' );
die $r->errmsg unless $r->ok;

$r = $machine->remote();

die $r->errmsg unless $r->noerr;
