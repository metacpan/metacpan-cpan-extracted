#!/usr/bin/perl -w

use strict;
use Getopt::Std 'getopts';

# The "size*" fields may be followed by a byte to get to an even alignment;
# it is not included into size! (Not applicable to these formats)
my $wav_header = <<EOH;			# Used for MP3???
  a4	# header: 'RIFF'
  V	# size: Size of what follows
  a4	# type: 'WAVE'

  a4	# type1: 'fmt ' subchunk
  V	# size1: Size of the rest of subchunk (usually 0x1e, sometime 0x20?)
  v	# format: 1 for pcm, 0x55 for mp3
  v	# channels: 2 stereo 1 mono
  V	# frequency
  V	# bytes_per_sec
  v	# bytes_per_sample
  v	# bits_per_sample_channel

  V	# Unknown1
  V	# Unknown2
  V	# Unknown3
  v	# Unknown4

  # v	# Unknown4a (when size1 is 0x20)

  # Optional section:
  # a4	# type12: 'fact' subchunk
  # V	# size12: Size of the rest of subchunk (4)
  # V	# Unknown5


  a4	# type2: 'data' subchunk
  V	# sizedata: Size of the rest of subchunk
EOH

my @wav_fields = ($wav_header =~ /^\s*\w+\s*#\s*(\w+)/mg);
my $header_size = length pack $wav_header, (0) x 20;	# No Optional part
sub MY_INF () {1e200}

my %opt;

sub wav_eat_header ($) {
  my $fh = shift;
  my $in;
  my $read = sysread $fh, $in, $header_size or die "can't read the header";
  my $prefix = '';
  return {prefix => $prefix, buf => $in} unless $read == $header_size;
  if ($opt{I} and $in =~ /^ID3(..)(.)([\x00-\x7f]{4})/s) {
    my $f = 0 + ord $2;			# Make into integer
    my $s = 0;
    for my $c (split //, $3) {
	$s <<= 7;
	$s |= ord $c;
    }
    $s += (($f & 0x10) ? 20 : 10);
    $read = sysread $fh, $in, $s, $header_size or die "can't read the header";
    return {buf => $in} unless $read == $s;
    $prefix = substr $in, 0, $s;
    $in = substr $in, $s;
  }
  my %vals;
  @vals{@wav_fields} = unpack $wav_header, $in or return {buf => $in};
  return {prefix => $prefix, buf => $in} unless $vals{header} eq 'RIFF';
  if ($vals{size1} == 0x20) {
    # Format above expects 0x1e...
    my $in2;
    $read = sysread $fh, $in2, 2 or die "can't read rest of the header";
    $in .= $in2;
    return {prefix => $prefix, buf => $in} unless $read == 2;
    my %vals1;
    @vals1{@wav_fields} = unpack $wav_header, substr $in, 2 or return {buf => $in};
    @vals{'type2', 'sizedata'} = @vals1{'type2', 'sizedata'};
  }
  if ($vals{type2} eq 'fact') {
    my $h2_size = length pack "V a4 V", (0) x 20;	# No Optional part
    my $in2;
    $read = sysread $fh, $in2, $h2_size or die "can't read rest of the header";
    $in .= $in2;
    return {prefix => $prefix, buf => $in} unless $read == $h2_size;
    @vals{qw[type12 size12]} = @vals{qw[type2 sizedata]};
    @vals{qw[Unknown5 type2 sizedata]} = unpack "V a4 V", $in2;
  }
  die <<EOD
Unexpected RIFF format:
 type='$vals{type}' (WAVE)
 type1='$vals{type1}' (fmt )
 size1=$vals{size1} (0x1e)
 format=$vals{format} (0x55)
 type12=$vals{type12} (fact)
 size12=$vals{size12} (4)
 type2=$vals{type2} (data)
EOD
    unless $vals{type} eq 'WAVE' and $vals{type1} eq 'fmt '
      and ($vals{size1} == 0x1e or $vals{size1} == 0x20)
	and $vals{format} == 0x55 
	  and (not exists $vals{type12} 
	       or $vals{type12} eq 'fact' and $vals{size12} eq 4)
	    and $vals{type2} eq 'data';
  $vals{buf} = $in;
  $vals{prefix} = $prefix;
  return \%vals;
}

# Typical usage:
# a) rename all .mp3 to .wav: pfind . "s/\.mp3$/.wav/i"
# b) run: eat_wav_mp3_header.pl -FdI -R .

# or, to list MP3 files with RIFF header
#  eat_wav_mp3_header.pl -IDM -R .


getopts('FGRdsIDM', \%opt); # Force, Glob, recurse, delete, silent, ID3v2-header-OK, Dry-run, input-is MP3
if ($opt{G}) {
  require File::Glob;			# "usual" glob() fails on spaces...
  @ARGV = map File::Glob::bsd_glob($_), @ARGV;
}

sub process_file ($) {
  my $f = shift;
  print "$f\n" unless $opt{s} or $opt{D};

  open IN, "< $f" or die;
  binmode IN;

  my $rc = wav_eat_header \*IN;

  if ($opt{D}) {	# Report only
    print "$f\n" if defined $rc->{type2};
    return;
  }
  (my $o = $f) =~ s/\.wav$/.mp3/i or die "`$f' is not with extension .wav";

  unless (defined $rc->{type2}) {
    close IN or die;
    die "File `$f': no valid RIFF header" unless $opt{F};
    rename $f, $o or die "rename `$f' => `$o': $!";
    return;
  }

  open OUT, ">$o" or die;
  binmode OUT;

  syswrite OUT, $rc->{prefix} if length $rc->{prefix};

  my ($in, $c);
  while ($c = sysread IN, $in, 1<<20) {
    syswrite OUT, $in or die;
  }
  close IN or die "close for read: $!";
  close OUT or die "close for write: $!";
  unlink $f or die "unlink: $!" if $opt{d};
}

if ($opt{R}) {
  require File::Find;
  File::Find::find({wanted => sub {return unless -f and ($opt{M} ? /\.mp3$/i : /\.wav$/i); process_file $_},
		    no_chdir => 1}, @ARGV);
} else {
  for my $f (@ARGV) {
    process_file $f;
  }
}
