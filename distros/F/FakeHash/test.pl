#!/usr/bin/perl
#
# Author: Mark-Jason Dominus  (mjd-perl-fakehash+@plover.com)
# This file, drawhash.pl, is in the public domain.

use FakeHash;

@ARGV = qw(When in the course of human events is becomes necessary for one people)
  unless @ARGV;

open PIC, "> test.pic" or die "Couldn't write to test.pic: $!; aborting";

my $hash = FakeHash::DrawHash->new();
$hash->draw_param('BUCKETSPACE', .25);
my $n = 0;
for $k (@ARGV) {
  last if $k =~ /#/;
#  print STDERR "About to insert $k\n";
  $hash->store($k, ++$n);
  $h{$k} = 'undef';
}
my @keylist = $hash->keys;
my @keylist2 = keys %h;

my $good = 1;
$good = 0 unless @keylist == @keylist2;
if ($good) {
  for (my $i = 0; $i < $keylist; ++$i) {
    $good = 0, last unless $keylist[$i] eq $keylist2[$i];
  }
}
unless ($good) {
  print STDERR <<EOM;
Ack!  Something is wrong!  
The keys in the simulated hash are:
  @keylist
but they keys in the real hash are:
  @keylist2
EOM
  exit 1;
}

# use Devel::Peek;
#Dump(\%h, 1 + scalar keys %h);

$hash->draw(\*PIC);
exit 0;

