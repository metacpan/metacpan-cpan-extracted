#!/usr/bin/perl -w
# 45B4dmH - mkTable.pl created by Pip Stuart <Pip@CPAN.Org> to select
#   odds from a MySQL server populated by runHands.pl && build an 
#   HTML summary of the results for all holes versus each number of
#   opponents.
# 2do:
#   save as data && sort holes by heads up winp
# This code is distributed under the GNU General Public License (version 2).

use strict;
use warnings;
use DBI;
use Time::PT;
use Games::Cards::Poker;

my $just = shift() || 0; # just param can print only certain opponent column
my %rprv = RPrV(); # reverse Progression Value lookup
my @holz = Holz(); # all holes
my %hols = ();     # holes as win% => holeAbbrev after searched
my %zloh = Zloh(); # reverse hole lookup
my %zplf = Zplf(); # reverse flop lookup
my $oppo; my $hole; my $dbhn; my $stmt; my @rowa; my $daba; my $rows;
my $totl; my $winp; my $ptb4; my $ptaf; my $tdif;

$ptb4 = Time::PT->new();
#printf("PTb4:$ptb4 expand:%s\n", $ptb4->expand());
$oppo = 1; $oppo = $just if($just);
foreach $hole (@holz) {
  my $ihol = $zloh{$hole};
  $daba = 'o' . $oppo; # build names as 'o1'..'o9'
  $dbhn = DBI->connect("DBI:mysql:$daba", undef, undef);
  $stmt = $dbhn->prepare("select wins, loss, ties from hole where hole_id='$ihol'");
  $stmt->execute();
  $rows = 0; @rowa = (); # reset rows && wins, loss, ties counts
  $rows = $stmt->rows(); # find row if defined
  @rowa = $stmt->fetchrow_array() if($rows); # defined so get values to incr
  $stmt->finish();
  $dbhn->disconnect();
  if($rows) {
    foreach(0..2) { $rowa[$_] = 0 unless(defined($rowa[$_]) && $rowa[$_]); }
    $totl = $rowa[0] + $rowa[1] + $rowa[2]; $totl = 1 unless($totl);
    $winp = ($rowa[0] / $totl) * 100;
    $hols{$winp} = $hole;
  }
}
print qq(<html><head><title>HoldEm Hole Odds</title></head>\n);
print qq(<body text="#A8F8F0" bgcolor="#03071B"><center>\n);
print qq(<h1>HoldEm Hole Odds generated on );
print $ptb4->color('HTML');
print qq( for just $just opponents) if($just);
print qq(</h1>\n<table border="1">\n);
print qq(<tr bgcolor="#1B0307"><th> <b>OPPONENTS</b> </th>);
if($just) {
                         print qq(<th colspan="2">$just</th>);
} else {
  foreach $oppo (1..9) { print qq(<th colspan="2">$oppo</th>); }
}
print qq(\n</tr><tr bgcolor="#031B07"><th> <b>HOLES</b> </th>);
if($just) {
                         print qq(<th bgcolor="#3B3B17">Runs</th><th bgcolor="#03172B">Win%</th>);
} else {
  foreach $oppo (1..9) { print qq(<th bgcolor="#3B3B17">Runs</th><th bgcolor="#03172B">Win%</th>); }
}
print qq(\n</tr>\n);
foreach (sort { $b <=> $a } keys(%hols)) {
  $hole = $hols{$_};
  my $ihol = $zloh{$hole};
  print qq(<tr><th bgcolor="#032B17">$hole</th>);
  foreach $oppo (1..9) {
    $oppo = $just if($just);
#printf("Running Test Case: Opponents:%d Hole:%-3s \n", $oppo, $hole);
    $daba = 'o' . $oppo; # build names as 'o1'..'o9'
    $dbhn = DBI->connect("DBI:mysql:$daba", undef, undef);
    $stmt = $dbhn->prepare("select wins, loss, ties from hole where hole_id='$ihol'");
    $stmt->execute();
    $rows = 0; @rowa = (); # reset rows && wins, loss, ties counts
    $rows = $stmt->rows(); # find row if defined
    @rowa = $stmt->fetchrow_array() if($rows); # defined so get values to incr
    $stmt->finish();
    $dbhn->disconnect();
    if($rows) {
      foreach(0..2) { $rowa[$_] = 0 unless(defined($rowa[$_]) && $rowa[$_]); }
      $totl = $rowa[0] + $rowa[1] + $rowa[2]; $totl = 1 unless($totl);
      $winp = sprintf("%3.2f", ($rowa[0] / $totl) * 100);
      print qq(<td bgcolor="#3B3B17">$totl</td><td>$winp%</td>);
#      printf("Total Runs:%31s\n      Wins:%31s / %8.4f%%\n      Loss:%31s / %8.4f%%\n      Ties:%31s / %8.4f%%\n       W+T:%31s / %8.4f%%\n", 
#             $totl, $rowa[0],              ($rowa[0]  / $totl) * 100,
#                    $rowa[1],              ($rowa[1]  / $totl) * 100,
#                    $rowa[2],              ($rowa[2]  / $totl) * 100,
#        ($rowa[0] + $rowa[2]), (($rowa[0] + $rowa[2]) / $totl) * 100);
    }
    last if($just);
  }
  print qq(</tr>\n);
}
print qq(</table></body></html>\n);
$ptaf = Time::PT->new();
#printf("PTaf:$ptaf expand:%s\n", $ptaf->expand());
$tdif = ($ptaf - $ptb4); # Time::Frame
#printf(" Dif:%s seconds:%s\n", $tdif->total_frames(), ($tdif->total_frames() / 60));
