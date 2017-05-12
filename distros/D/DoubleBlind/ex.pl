#!/usr/bin/perl -w
use strict;
use DoubleBlind;

# perl -Mblib=J:\test-programs\perl\modules\DoubleBlind J:\test-programs\perl\modules\DoubleBlind\ex.pl starttrack=1 tracks=6 first_meth=0 >& xx

# It is important to redirect output, since it hints on what is happening
# Moreover, it makes sense to do
#  touch o/*
# afterward to avoid (possibly revealing) gaps in creation time

sub lame ($$$) {
  my($from, $to, $opts) = (shift, shift, shift);
  system qw(lame -h), @$opts, $from, 'tmp.mp3' and die "call lame: $!";
  system qw(lame --decode), 'tmp.mp3', $to and die "call lame: $!";
  unlink 'tmp.mp3' or die "unlink: $!";
}

sub ogg ($$$) {
  my($from, $to, $opts) = (shift, shift, shift);
  system qw(oggenc -o), 'tmp.ogg', @$opts, $from and die "call lame: $!";
  system qw(oggdec -o), $to, 'tmp.ogg' and die "call lame: $!";
  unlink 'tmp.ogg' or die "unlink: $!";
}

sub by_cp ($$$) {
  my($from, $to, $opts) = (shift, shift, shift);
  #use File::Copy 'copy';
  #copy $from, $to or die;	# Won't update time, so differs from the rest...
  system qw(cp), $from, $to and die "call cp: $!"; # Update time, as others do
}

my @meth = (
  [\&by_cp, [qw[]]],
  [\&ogg,  [qw[--quality 10]]],
  [\&ogg,  [qw[--quality 9]]],
  [\&lame, [qw[--preset insane]]],
  [\&lame, [qw[--preset extreme]]],
  [\&lame, [qw[--preset standard]]],
);

sub recode ($$$) {
  my ($file, $method, $label) = (shift, shift, shift, shift);
  $method = $meth[$method];
  (my $ofile = $file) =~ s,^(.*[/\\]|),${1}o/, or die;
  $method->[0]->($file, $ofile, $method->[1]);
}


die <<EOD
Usage: $0 starttrack=T tracks=N first_meth=M
  T >= 1, N, M >= 0 are numbers.  N tracks are processed, with methods M..M+N-1
EOD
   unless @ARGV == 3
	 and my($tr) = ($ARGV[0] =~ /^starttrack=(\d+)$/)
	 and my($nt) = ($ARGV[1] =~ /^tracks=(\d+)$/)
	 and my($fm) = ($ARGV[2] =~ /^first_meth=(\d+)$/);

open F, '>> tracks-labels' or die;
sub cb($$$) { my ($n, $id, $label) = (shift, shift, shift);
	      $n += $tr - 1;
	      print F "track=$n\t==>\t$label\n";
              recode sprintf('audio_%02d.wav', $n), $id, $label}
print DoubleBlind::process_shuffled \&cb, 6, 0;
close F or die;

# The double-blind labels are appended to the file `tracks-labels'.

# Reading and writing:

# readcd -fulltoc dev=0,1,0 -f=audio_cd >&nul && cdda2wav dev=0,1,0 cddb=0 -bulk

# Keep in mind that re-encoding creates audio files with length
# NOT proportional to the audio sector size.  In particular, one needs to
# add -pad option to cdrecord, and redirect warnings - otherwise warnings
# will make it clear which audio files are just copied, and which are
# re-encoded.  (Manually copy .inf files if needed for the following:)

# cdrecord driveropts=burnfree -fs=64m dev=0,1,0 -pad -dao -useinfo -text -audio *.wav >& cdrec-out

# Look for errors and the list of written tracks (and no other HINTS!) by
#   grep Track cdrec-out
#   grep -A5 -i error cdrec-out
