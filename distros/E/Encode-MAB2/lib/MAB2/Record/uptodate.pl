#!/usr/bin/perl -w

use strict;
use LWP::Simple qw(mirror);

=pod

With this script we try to check if the files specifying the MAB2
standard have changed since the last download. If there are newer
files, they are downloaded and we call the external diff program to
see what has changed. Copying the changed file into the according
module is left to manual intervention.

=cut


my $baseurl = qq{ftp://ftp.ddb.de/pub/mab/};

my(%map) = qw(
  segm000   Base
  adressmab NULL
  gkdmab    gkd
  lokalmab  lokal
  notatmab  NULL
  pndmab    pnd
  swdmab    swd
  titelmab  titel
);

my $all304 = 1;
for my $doc (keys %map) {
  my $url = "$baseurl$doc.txt";
  my $code = mirror $url, "$doc.txt" or die "Could not get $url";
  warn "doc[$doc]code[$code]";
  $all304 = 0 unless $code == 304;
}

if ($all304) {
  print "No document has changed since last download.\n";
  exit;
}

for my $doc (keys %map) {
  next if $map{$doc} eq "NULL";
  local $/;
  open F, "$map{$doc}.pm" or die "Could not open $map{$doc}.pm: $!";
  my $pm = <F>;
  open F, "$doc.txt" or die "Could not open $doc.txt: $!";
  my $txt = <F>;
  close F;
  $pm =~ s/^.*__DATA__\n//s;
  if ($pm eq $txt) {
    print "Document $doc unchanged\a\n";
    sleep 2;
    next;
  }

  system "diff -u $map{$doc}.pm $doc.txt|less";
  print "Enter RET\n";
  my $foo = <>;
}
