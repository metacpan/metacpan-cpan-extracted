#!/usr/bin/perl -w

use File::Find 'find';
use MP3::Info;

$MP3::Info::try_harder = 1;

my (@f,$r);
$r = shift if @ARGV and lc $ARGV[0] eq '-r';

die "Usage: $0 [-r] FILENAMES" unless @ARGV;
if ($r) {
  find sub { -f and /\.mp3/i and push @f, $File::Find::name }, @ARGV
} else {
  @f = @ARGV;
}

die "No files found" unless @f;
my $t = 0;
for my $f (@f) {
  my $info = get_mp3info($f);
  warn("No mp3info for `$f': $@\n"), next unless defined $info;
  $t += $info->{SECS}
}
#my @l = `mp3info -p "%S\n" @f`;
#$t += $_ for @l;
my $h = int($t/3600);
my $m = int(($t - 3600 * $h)/60);
my $s = $t - 3600 * $h - 60 * $m;
printf "%.1f = %d:%02d:%02.1f\n", $t, $h, $m, $s;
