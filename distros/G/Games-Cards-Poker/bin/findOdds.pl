#!/usr/bin/perl -w
# 4569wCs - findOdds.pl created by Pip Stuart <Pip@CPAN.Org> to select
#   odds from a MySQL server populated by runHands.pl.  You pass in a
#   current scenario to return the likelihood that your hand will win
#   assuming everyone remains in the hand until the end.
# Parameters are: #_of_opponents, hole_ShortHand, flop_ShortHand, turn, rivr
#   where the last two omit their suits.
#
#   Useful stuff to calc:
#     # of ways to get each possible hole (combos) (see mkParts.pl)
#     For each possible hole:
#       Hands You Win         && %
#       Hands You Lose        && %
#       Hands You Tie         && %
#       Hands You Don't Lose  && % (Win + Tie)
#
# This code is distributed under the GNU General Public License (version 2).

use strict;
use warnings;
use DBI;
use Time::PT;
use Games::Cards::Poker;

my %rprv = RPrV(); # reverse Progression Value lookup
my %zloh = Zloh(); # reverse hole lookup
my %zplf = Zplf(); # reverse flop lookup
my $oppo = shift() || 9;
my $hole = shift() || 'AA';   my $ihol = $zloh{$hole} if(defined($hole));
my $flop = shift() || undef;  my $iflp = $zplf{$flop} if(defined($flop));
my $turn = shift() || undef;  my $itrn = $rprv{$turn} if(defined($turn));
my $rivr = shift() || undef;  my $irvr = $rprv{$rivr} if(defined($rivr));
my $dbhn; my $stmt; my @rowa; my $daba; my $rows; my $totl;
my $ptb4; my $ptaf; my $tdif;

printf("Running Test Case: Opponents:%d Hole:%-3s ", $oppo, $hole);
printf("Flop:%-4s ", $flop) if(defined($flop));
print  "Turn:$turn "        if(defined($turn));
print  "Rivr:$rivr "        if(defined($rivr));
print "\n";
$ptb4 = Time::PT->new();
printf("PTb4:$ptb4 expand:%s\n", $ptb4->expand());
$daba = 'o' . $oppo; # build names as 'o1'..'o9'
$dbhn = DBI->connect("DBI:mysql:$daba", undef, undef);
if     (!defined($flop)) { # select to see if hole row already exists
  $stmt = $dbhn->prepare("select wins, loss, ties from hole where hole_id='$ihol'");
  $stmt->execute();
  $rows = 0; @rowa = (); # reset rows && wins, loss, ties counts
  $rows = $stmt->rows(); # find row if defined
  @rowa = $stmt->fetchrow_array() if($rows); # defined so get values to incr
} elsif(!defined($turn)) { # select to see if flop row already exists
  $stmt = $dbhn->prepare("select wins, loss, ties from flop where (flop_id='$iflp' && hole_id='$ihol')");
  $stmt->execute();
  $rows = 0; @rowa = (); # reset rows && wins, loss, ties counts
  $rows = $stmt->rows(); # find row if defined
  @rowa = $stmt->fetchrow_array() if($rows); # defined so get values to incr
} elsif(!defined($rivr)) { # select to see if turn row already exists
  $stmt = $dbhn->prepare("select wins, loss, ties from turn where (turn_id='$itrn' && flop_id='$iflp' && hole_id='$ihol')");
  $stmt->execute();
  $rows = 0; @rowa = (); # reset rows && wins, loss, ties counts
  $rows = $stmt->rows(); # find row if defined
  @rowa = $stmt->fetchrow_array() if($rows); # defined so get values to incr
} else                   { # select to see if rivr row already exists
  $stmt = $dbhn->prepare("select wins, loss, ties from rivr where (rivr_id='$irvr' && turn_id='$itrn' && flop_id='$iflp' && hole_id='$ihol')");
  $stmt->execute();
  $rows = 0; @rowa = (); # reset rows && wins, loss, ties counts
  $rows = $stmt->rows(); # find row if defined
  @rowa = $stmt->fetchrow_array() if($rows); # defined so get values to incr
}
$stmt->finish();
$dbhn->disconnect();
if($rows) {
  $totl = $rowa[0] + $rowa[1] + $rowa[2]; $totl = 1 unless($totl);
  foreach(0..2) { $rowa[$_] = 0 unless(defined($rowa[$_]) && $rowa[$_]); }
  printf("Total Runs:%31s\n      Wins:%31s / %8.4f%%\n      Loss:%31s / %8.4f%%\n      Ties:%31s / %8.4f%%\n       W+T:%31s / %8.4f%%\n", 
         $totl, $rowa[0],              ($rowa[0]  / $totl) * 100,
                $rowa[1],              ($rowa[1]  / $totl) * 100,
                $rowa[2],              ($rowa[2]  / $totl) * 100,
    ($rowa[0] + $rowa[2]), (($rowa[0] + $rowa[2]) / $totl) * 100);
} else {
  printf("!*EROR*! Test Case not explored yet!\n");
}
$ptaf = Time::PT->new();
printf("PTaf:$ptaf expand:%s\n", $ptaf->expand());
$tdif = ($ptaf - $ptb4); # Time::Frame
printf(" Dif:%s seconds:%s\n", $tdif->total_frames(), ($tdif->total_frames() / 60));
