#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

sub diag {
  print STDERR @_;
  print STDERR "\n";
}

sub safe_exec {
  my ( $command, @params ) = @_;
  diag("running $command @params");
  my $exit = system( $command, @params );
  if ( $exit != 0 ) {
    my $low  = $exit & 0b11111111;
    my $high = $exit >> 8;
    warn "$command failed: $? $! and exit = $high , flags = $low";
    if ( $high != 0 ) {
      exit $high;
    }
    else {
      exit 1;
    }
  }
  return 1;
}

if ( not exists $ENV{STERILIZE_ENV} ) {
  diag('STERILIZE_ENV unset');
  exit 0;
}
if ( $ENV{STERILIZE_ENV} < 1 ) {
  diag('STERLIZIE_ENV < 1, Not Sterilizing');
  exit 0;
}
if ( not exists $ENV{TRAVIS} ) {
  diag('Is not running under travis!');
  exit 1;
}
for my $i (@INC) {
  next if $i !~ /site/;
  next if $i eq '.';
  diag( 'Sterilizing files in ' . $i );
  safe_exec( 'find', $i, '-type', 'f', '-delete' );
  diag( 'Sterilizing dirs in ' . $i );
  safe_exec( 'find', $i, '-depth', '-type', 'd', '-delete' );
}

