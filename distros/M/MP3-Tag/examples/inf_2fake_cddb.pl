#!/usr/bin/perl -w

# Read .inf files from current directory, produce a leader of a cddb file
# on STDOUT (processable with `fdquery --i file' from Net::FreeDB2)

use strict;

my @inf;

for my $file (<*.inf>) {
  local *F;
  open F, $file or die;
  my @lines = <F>;
  close F or die;
  chomp @lines;
  my %line;
  for my $line (@lines) {
    next if $line =~ /^\s*#/;
    die unless $line =~ /^\s*(\S+)\s*=\s*(.*?)\s*$/;
    $line{lc $1} = $2;
  }
  die unless exists $line{tracknumber};
  $inf[$line{tracknumber}] = \%line;
}

for my $n (1..$#inf) {
  die "Missing track number $n" unless defined $inf[$n];
}

print <<EOP;
# xmcd
#
# Track frame offsets:
EOP

for my $n (1..$#inf) {
  my $start = $inf[$n]{trackstart} + 150;
  print "# $start\n";
}

my @length = map { $inf[$_]{tracklength} =~ /(\d+)/; $1 } 1..$#inf;
my $length = int (($inf[-1]{trackstart} + $length[-1] - $inf[1]{trackstart})/75 + 2);

#my $diskid = compute_discid ($inf[1]{trackstart} + 150, @length);
my $diskid = $inf[1]{cddb_discid};
$diskid =~ s/^0x//i;

print <<EOP;
#
# Disc length: $length seconds
#
# Revision: 5
# Submitted via: not submitted yet
DISCID=$diskid
EOP


# Usage:
#
#      my $id = compute_discid ($leader, @frames);
#
# "$leader" is the number of frames before track 1.
# "@frames" is the length in frames of each track on the disc.
# (A frame is 1/75th of a second.)
# Returns the disc ID as a string.

sub cddb_sum {
  # a number like 2344 becomes 2+3+4+4 (13).
  my ($n) = @_;
  my $ret = 0;
  while ($n > 0) {
    $ret += ($n % 10);
    $n /= 10;
  }
  return $ret;
}

sub compute_discid {
  my @frames = @_;

  my $tracks = $#frames + 1;
  my $n = 0;

  my @start_secs;
  my $i;

  for ($i = 0; $i < $tracks; $i++) {
    $start_secs[$i] = int ($frames[$i] / 75);
  }

  for ($i = 0; $i < $tracks-1; $i++) {
    $n = $n + cddb_sum ($start_secs[$i]);
  }

  my $t = $start_secs[$tracks-1] - $start_secs[0];

  my $id = ((($n % 0xFF) << 24) | ($t << 8) | $tracks-1);
  return sprintf ("%08x", $id);
}

