#!/usr/bin/perl -w

# Read a file (from STDIN) created via (e.g.)
#   readcd2 -fulltoc dev=0,1,0 -f=audio_cd
# , produce a leader of a cddb file on STDOUT
# (processable with `fdquery --i file' from Net::FreeDB2, or cddb2cddb)

use strict;
use MP3::Tag;

my $round_offset = 0;	# Rounding down gives better match to initial size...
binmode STDIN;
my $in = do { local $/;  <STDIN> };
my $s = 2 + unpack 'n', $in;
my $s1 = length $in;
die "TOC size mismatch: header=$s, actual=$s1" unless $s == $s1;
my %chunks = unpack 'x4 (x3 C x4 a3)*', $in;

sub msf2_sector {
  my ($m,$s,$f) = unpack 'CCC', shift;
  $f + 75*($s + 60*$m)		# Apparently, already shifted by 150
}

my @tracks = sort {$a <=> $b} grep $_ <= 99, keys %chunks;
die "Gaps in tracks (@tracks)" unless @tracks == $tracks[-1] and $tracks[0] == 1;
my @sect = map msf2_sector($_), @chunks{@tracks, 0xa2};	# 0xa2 is leadout
#print "$_\n" for @sect;
#exit;

my @l = map $sect[$_] - $sect[$_ - 1], 1..$#sect;

print <<EOP;
# xmcd
#
# Track frame offsets:
EOP

for my $start (@sect[0..$#sect - 1]) {
  print "# $start\n";
}

my $length = int ($sect[-1]/75);

my $diskid = compute_discid_my (@sect);
$diskid =~ s/^0x//i;

print <<EOP;
#
# Disc length: $length seconds
#
# Revision: 5
# Submitted via: not submitted yet
DISCID=$diskid
EOP

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

sub compute_discid_my {
  my @sect = @_;
  my @secs = map int($_/75), @sect;	# cdda2wav rounds down
  my $n = 0;
  $n += cddb_sum($_) for @secs[0 .. $#secs - 1];	# Skip leadout
  my $t = $secs[-1] - $secs[0];
  return sprintf '%08x', (($n % 0xFF) << 24) | ($t << 8) | (@secs - 1);
}

