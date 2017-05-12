#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Path::Tiny;
use Data::Dump qw( pp );

my ($bomb) = pack 'C*', 0xEF, 0xBB, 0xBF;

sub read_bom_segment {
  my ($file) = @_;
  my $fh = path($file)->openr_raw();
  my $bytes;
  if ( not read $fh, $bytes, 3 ) {
    die "Cant read $file";
  }
  return $bytes;
}

sub is_bom {
  my ($bom) = @_;
  use bytes;
  return $bom eq $bomb;
}

sub rewrite_without_bom {
  my ($file) = @_;
  my $rfh    = path($file)->openr_raw();
  my $wfh    = path( $file . '.new' )->openw_raw();
  my $bytes;
  read $rfh, $bytes, 3;
  while ( read $rfh, $bytes, 8192 > 0 ) {
    $wfh->print($bytes);
  }
  close $rfh or warn "Closing $file read failed";
  close $wfh or warn "Closing $file write failed";
  path( $file . '.new' )->move($file);
}

pp( { BOM => $bomb } );

for my $file (@ARGV) {
  my $path = path($file);
  *STDERR->print("Checking $path\n");
  my $bom_bytes = read_bom_segment($path);
  next unless is_bom($bom_bytes);
  *STDERR->print("BOM found, rewriting\n");
  rewrite_without_bom($path);
}

