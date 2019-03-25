#!/usr/bin/perl -w

# Read .inf files from current directory, produce a leader of a cddb file
# on STDOUT (processable with `fdquery --i file' from Net::FreeDB2)

use strict;
use MP3::Info;

my @sect = 150;
my @l;

my $round_offset = 0;	# Rounding down gives better match to initial size...
for my $file (<*.mp3>) {
  my $mp3 = MP3::Info::get_mp3info($file);
  my $t = $mp3->{SECS};
  $t = int($round_offset + $t*75) or warn;	# 75 sectors per sec...
  push @l, $t;
  push @sect, $sect[-1] + $t;
}

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
#my $diskid = $inf[1]{cddb_discid};
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

