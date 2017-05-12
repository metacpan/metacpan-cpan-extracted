#!/usr/bin/perl -w
use strict;

@ARGV == 1 or die "Usage: $0 Composer_Name\n";
$ARGV[0] eq 'Beethoven' or die "Only Beethoven supported now...\n";
shift;

my $url_get_txt = 'lynx -width=400 -number_links- -nolist -dump';

sub get_url_txt ($) {
  my ($url, $f) = shift;
  local %ENV = %ENV;
  delete $ENV{LYNX_CFG};
  delete $ENV{LYNX_LSS};
  local $ENV{HOME} = '/';
  open $f, "$url_get_txt $url |" or die "open lynx pipe for read: $|";
  $f
}

my $f = get_url_txt 'http://en.wikipedia.org/wiki/List_of_works_by_Beethoven';
# XXXX Actually, we "want" writing years, not publication year; need to
#      pull it from some other place
my ($work, $op, $no, $opyears, %opus, %opnums, %op_publ_year);
while (<$f>) {
  $work++ if /^\s*Works having assigned Opus/;
  next unless $work;
  s/\.?\s*$//;
  if (s/^\s*\*\s*(\w+\s.*?):\s*//) {
    $op = $1;
    $op =~ s/\bOpus\b/Op./;
    $no = 0;
    $op_publ_year{$op} = ( s/\s*(\([-\d]+\))\s*$// ? " $1" : '' );
    $opus{$op} = "$_; $op$op_publ_year{$op}\n";
  } elsif (s/^\s*\+\s*//) {
    $no++;
    $opus{$op} =~ s/^#*\s*/### /;
    push @{$opnums{$op}}, "$_; $op, No. $no$op_publ_year{$op}\n";
  }
}
close $f or die "error closing lynx pipe: $!";

sub alignnums ($) {
  my $s = shift;
  $s =~ s/(\d+)/ sprintf '%029d', $1/ge;
  $s
}

for (sort {alignnums($a) cmp alignnums $b} keys %opus) {
  print $opus{$_};
  print for @{$opnums{$_}};
}

