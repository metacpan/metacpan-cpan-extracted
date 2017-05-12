#!/usr/bin/perl
# ckOdds.pl created by Pip Stuart <Pip@CPAN.Org> to query pre-calculated
#   Poker odds from a generated file hierarchy of XML files.
# This code is distributed under the GNU General Public License (version 2).

use XML::XPath;
use XML::XPath::XMLParser;
my $thip = '.'; my $oppo = 1; my $limt; my $wins; my $ties; my $loss;
my $pott = shift() || 15;
my $shrt = shift() || 'AA';
my $shfl = shift() || 'AAK';
my $shtr = shift() || 'K';
my $shrv = shift() || 'K';

sub CkStats {
  if($shrt) {
    if($shfl) {
      if($shtr) {
        if($shrv) {
          if(-r "$thip/h$shrt/f$shfl.ppx") {
            $xpth = XML::XPath->new('filename' => "$thip/h$shrt/f$shfl.ppx");
            if($xpth->exists("/f$shfl/t$shtr/r$shrv")) {
              my $wval = $xpth->findvalue("/f$shfl/t$shtr/r$shrv/\@w"); # find wins attribute
              my $tval = $xpth->findvalue("/f$shfl/t$shtr/r$shrv/\@t"); # find ties attribute
              my $lval = $xpth->findvalue("/f$shfl/t$shtr/r$shrv/\@l"); # find loss attribute
              my $summ = "$wval" + "$tval" + "$lval";
              $wins = ("$wval" / $summ);
              $ties = ("$tval" / $summ);
              $loss = ("$lval" / $summ);
            } else {
              $wins = 'NA'; $ties = 'NA'; $loss = 'NA';
            }
          } else {
            $wins = 'NA'; $ties = 'NA'; $loss = 'NA';
          }
        } elsif(-r "$thip/h$shrt/f$shfl.ppx") {
          $xpth = XML::XPath->new('filename' => "$thip/h$shrt/f$shfl.ppx");
          if($xpth->exists("/f$shfl/t$shtr")) {
            my $wval = $xpth->findvalue("/f$shfl/t$shtr/\@w"); # find wins attribute
            my $tval = $xpth->findvalue("/f$shfl/t$shtr/\@t"); # find ties attribute
            my $lval = $xpth->findvalue("/f$shfl/t$shtr/\@l"); # find loss attribute
            my $summ = "$wval" + "$tval" + "$lval";
            $wins = ("$wval" / $summ);
            $ties = ("$tval" / $summ);
            $loss = ("$lval" / $summ);
          } else {
            $wins = 'NA'; $ties = 'NA'; $loss = 'NA';
          }
        } else {
          $wins = 'NA'; $ties = 'NA'; $loss = 'NA';
        }
      } elsif(-r "$thip/h$shrt/f$shfl.ppx") {
        $xpth = XML::XPath->new('filename' => "$thip/h$shrt/f$shfl.ppx");
        if($xpth->exists("/f$shfl")) {
          my $wval = $xpth->findvalue("/f$shfl/\@w"); # find wins attribute
          my $tval = $xpth->findvalue("/f$shfl/\@t"); # find ties attribute
          my $lval = $xpth->findvalue("/f$shfl/\@l"); # find loss attribute
          my $summ = "$wval" + "$tval" + "$lval";
          $wins = ("$wval" / $summ);
          $ties = ("$tval" / $summ);
          $loss = ("$lval" / $summ);
        } else {
          $wins = 'NA'; $ties = 'NA'; $loss = 'NA';
        }
      } else {
        $wins = 'NA'; $ties = 'NA'; $loss = 'NA';
      }
    } elsif(-r "$thip/h.ppx") {
      $xpth = XML::XPath->new('filename' => "$thip/h.ppx");
      if($xpth->exists("/h/h$shrt")) {
        my $wval = $xpth->findvalue("/h/h$shrt/\@w"); # find wins attribute
        my $tval = $xpth->findvalue("/h/h$shrt/\@t"); # find ties attribute
        my $lval = $xpth->findvalue("/h/h$shrt/\@l"); # find loss attribute
        my $summ = "$wval" + "$tval" + "$lval";
        $wins = ("$wval" / $summ);
        $ties = ("$tval" / $summ);
        $loss = ("$lval" / $summ);
      } else {
        $wins = 'NA'; $ties = 'NA'; $loss = 'NA';
      }
    } else {
      $wins = 'NA'; $ties = 'NA'; $loss = 'NA';
    }
  }
  if($oppo > 1 && $wins < 1) {
    $wins  = ($wins ** $oppo);
    $ties += ($ties * (1 - $wins)) if($ties + ($ties * (1 - $wins)) < (1 - $wins));
    $loss  = (1 - $wins - $ties);
  }
  $limt = $wins * $pott;
  unless($wins eq 'NA' || $ties eq 'NA' || $loss eq 'NA') {
    $wins = sprintf("%8.4f%%", ($wins * 100));
    $ties = sprintf("%8.4f%%", ($ties * 100));
    $loss = sprintf("%8.4f%%", ($loss * 100));
  }
}

#print "shrt:$shrt shfl:$shfl shtr:$shtr shrv:$shrv\n";
for($oppo = 1; $oppo <= 9; $oppo++) {
  CkStats();
  printf("oppo:$oppo w:%8s t:%8s l:%8s  don't bet more than:\$%7.2f\n", $wins, $ties, $loss, $limt);
}
