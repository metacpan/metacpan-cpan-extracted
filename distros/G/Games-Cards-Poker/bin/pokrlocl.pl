#!/usr/bin/perl -w
# 47B2OQS - pokrlocl.pl created by Pip Stuart <Pip@CPAN.Org>
#   to provide a local interactive (Perl/Tk) interface to pokr odds.
# 2do:
#   scrutinize multi-oppo odds (get as close as possible)
#     (tst hole:Q7 as 50% heads-up down to ~10% vs9)
#   mk user profile, stats logging, summary
#   add szmd togl to delete && recreate all
#   add nvrt togl to delete && recreate all
#   add menus
# This code is distributed under the GNU General Public License (version 2).

use strict;
use Tk;
#use Tk::Thumbnail;
#use Tk::widgets qw(PNG);
use XML::XPath;
use XML::XPath::XMLParser;

my $szmd = shift || 0;
my $ppth = '.'; my $wins = ''; my $ties = ''; my $loss = ''; my $limt = ''; my $runs = '';
my $ipth = '../crdz'; # image path
my $mwin = MainWindow->new();
my $fram = $mwin->Frame(-background => '#03071B')->grid();
my @sutz = qw( s h d c );
my @rnkz = qw( A K Q J T 9 8 7 6 5 4 3 2 );
my %ztus; for(my $indx = 1; $indx <= @sutz; $indx++) { $ztus{$sutz[$indx - 1]} = $indx; }
my %zknr; for(my $indx = 1; $indx <= @rnkz; $indx++) { $zknr{$rnkz[$indx - 1]} = $indx; }
my $shrt = ''; my $shfl = ''; my $shtr = ''; my $shrv = ''; my $colm = 0;
my @imgz = (); my @lblz = (); my @crdz = (); my $lppx = ''; my $roww = 0;
my $oppo =  1; my $pott =  0; my $lilb =  1; my $bigb =  2;
my $ltxt = ''; my $xpth;
my $fnt0 = 'times   20 bold'; # 20 16
my $fnt1 = 'courier 20 bold'; # 20 16
my $sufx = '.bmp'; my $sufp = '_i';
unless($szmd) {
  $sufx = '-vga.bmp';
  $sufp =         '';
}

sub CkStats {
  $shrt = ''; $shfl = ''; $shtr = ''; $shrv = '';
  if(@crdz >= 2) {
    if($zknr{substr($crdz[0], 0, 1)} <= $zknr{substr($crdz[1], 0, 1)}) {
      $shrt = substr($crdz[0], 0, 1) . substr($crdz[1], 0, 1);
    } else {
      $shrt = substr($crdz[1], 0, 1) . substr($crdz[0], 0, 1);
    }
    $shrt .= 's' if(substr($crdz[0], 1, 1) eq substr($crdz[1], 1, 1));
    if(@crdz >= 5) {
      if($zknr{substr($crdz[2], 0, 1)} < $zknr{substr($crdz[3], 0, 1)}) {
        if     ($zknr{substr($crdz[3], 0, 1)} < $zknr{substr($crdz[4], 0, 1)}) {
          $shfl = substr($crdz[2], 0, 1) .  substr($crdz[3], 0, 1) .  substr($crdz[4], 0, 1);
        } elsif($zknr{substr($crdz[2], 0, 1)} < $zknr{substr($crdz[4], 0, 1)}) {
          $shfl = substr($crdz[2], 0, 1) .  substr($crdz[4], 0, 1) .  substr($crdz[3], 0, 1);
        } else {
          $shfl = substr($crdz[4], 0, 1) .  substr($crdz[2], 0, 1) .  substr($crdz[3], 0, 1);
        }
      } else {
        if     ($zknr{substr($crdz[2], 0, 1)} < $zknr{substr($crdz[4], 0, 1)}) {
          $shfl = substr($crdz[3], 0, 1) .  substr($crdz[2], 0, 1) .  substr($crdz[4], 0, 1);
        } elsif($zknr{substr($crdz[3], 0, 1)} < $zknr{substr($crdz[4], 0, 1)}) {
          $shfl = substr($crdz[3], 0, 1) .  substr($crdz[4], 0, 1) .  substr($crdz[2], 0, 1);
        } else {
          $shfl = substr($crdz[4], 0, 1) .  substr($crdz[3], 0, 1) .  substr($crdz[2], 0, 1);
        }
      }
      $shfl .= 's' if(substr($crdz[2], 1, 1) eq substr($crdz[3], 1, 1) &&
                      substr($crdz[3], 1, 1) eq substr($crdz[4], 1, 1));
      if(@crdz >= 6) {
        $shtr = substr($crdz[5], 0, 1);
        if(@crdz == 7) {
          $shrv = substr($crdz[6], 0, 1);
        }
      }
    }
  }
  $wins = ''; $ties = ''; $loss = ''; $limt = ''; $runs = ''; $ltxt = '';
  if($shrt) {
    if($shfl) {
      if($shtr) {
        if($shrv) {
          if(-r "$ppth/h$shrt/f$shfl.ppx") {
            unless($lppx eq "$ppth/h$shrt/f$shfl.ppx") {
              $lppx = "$ppth/h$shrt/f$shfl.ppx";
              $xpth = XML::XPath->new('filename' => $lppx);
            }
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
        } elsif(-r "$ppth/h$shrt/f$shfl.ppx") {
          unless($lppx eq "$ppth/h$shrt/f$shfl.ppx") {
            $lppx = "$ppth/h$shrt/f$shfl.ppx";
            $xpth = XML::XPath->new('filename' => $lppx);
          }
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
      } elsif(-r "$ppth/h$shrt/f$shfl.ppx") {
        unless($lppx eq "$ppth/h$shrt/f$shfl.ppx") {
          $lppx = "$ppth/h$shrt/f$shfl.ppx";
          $xpth = XML::XPath->new('filename' => $lppx);
        }
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
    } elsif(-r "$ppth/h.ppx") {
      unless($lppx eq "$ppth/h.ppx") {
        $lppx = "$ppth/h.ppx";
        $xpth = XML::XPath->new('filename' => $lppx);
      }
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
  if($oppo > 1 && $wins !~ /^(NA)?$/ && $wins < 1) {
    my $swin = $wins;
    foreach(1..$oppo) {
      my $dwin = $wins;
      $wins *= $swin;
      $wins += $dwin;
      $wins /=     2;
    }
#    $wins  = ($wins ** $oppo);
    $ties += ($ties * (1 - $wins)) if($ties + ($ties * (1 - $wins)) < (1 - $wins));
    $loss  = (1 - $wins - $ties);
  }
  $limt = sprintf("\$%7.2f", ($wins * $pott)) unless($wins =~ /^(NA)?$/);
  $ltxt = "pott: \$$pott  limt: $limt"        unless($wins =~ /^(NA)?$/);
  $wins = sprintf("%8.4f%%", ($wins * 100))   unless($wins =~ /^(NA)?$/);
  $ties = sprintf("%8.4f%%", ($ties * 100))   unless($ties =~ /^(NA)?$/);
  $loss = sprintf("%8.4f%%", ($loss * 100))   unless($loss =~ /^(NA)?$/);
  if(-r "$ppth/h.ppx") {
    unless($lppx eq "$ppth/h.ppx") {
      $lppx = "$ppth/h.ppx";
      $xpth = XML::XPath->new('filename' => $lppx);
    }
    if($xpth->exists("/h")) {
      my $wval = $xpth->findvalue("/h/\@w"); # find wins attribute
      my $tval = $xpth->findvalue("/h/\@t"); # find ties attribute
      my $lval = $xpth->findvalue("/h/\@l"); # find loss attribute
      my $summ = "$wval" + "$tval" + "$lval";
      if(defined($summ) && $summ) {
        $summ = reverse($summ); $summ =~ s/(.{3})/$1,/g;
        $summ = reverse($summ); $summ =~ s/^,//;
      }
      $runs = $summ;
    } else {
      $runs = '';
    }
  } else {
    $runs = '';
  }
}

sub HndlCrdz {
  my $self = shift() || return();
  my $newc = shift() || return();
  my @posi = (2, 3, 5, 6, 7, 9, 11); # hole/bord card column positions
  if     ($newc =~ /^o(\d)$/) {
    if($1) { $oppo = $1; }
    else   { $oppo++; $oppo = 1 if($oppo == 10); }
    $imgz[0][5]->delete();
    $lblz[0][5]->destroy();
    $imgz[0][5] = $mwin->Photo(-file => "$ipth/o$oppo$sufx");
    $lblz[0][5] = $fram->Label(-image => $imgz[0][5],  -background => '#03071B', -foreground => '#88B8D0')->grid(-row => 5, -column => 0, -sticky => 'n');
    $lblz[0][5]->bind('<Button-1>' => [ \&HndlCrdz, 'o0' ]);
  } elsif($newc !~ /^p\d$/ && @crdz < 7) {
    push(@crdz, $newc);
    ($imgz[$posi[$#crdz]][5], $imgz[$zknr{substr($newc, 0, 1)} - 1][$ztus{substr($newc, 1, 1)}]) =
      ($imgz[$zknr{substr($newc, 0, 1)} - 1][$ztus{substr($newc, 1, 1)}], $imgz[$posi[$#crdz]][5]);
    ($lblz[$posi[$#crdz]][5], $lblz[$zknr{substr($newc, 0, 1)} - 1][$ztus{substr($newc, 1, 1)}]) =
      ($lblz[$zknr{substr($newc, 0, 1)} - 1][$ztus{substr($newc, 1, 1)}], $lblz[$posi[$#crdz]][5]);
    $lblz[$posi[$#crdz]][5]->grid(-row => 5, -column => $posi[$#crdz], -sticky => 'n');
    $lblz[$zknr{substr($newc, 0, 1)} - 1][$ztus{substr($newc, 1, 1)}]->grid(-row => $ztus{substr($newc, 1, 1)}, -column => ($zknr{substr($newc, 0, 1)} - 1), -sticky => 'n');
    $lblz[$posi[$#crdz]][5]->bind('<Button-1>' => [ \&HndlCrdz, "p$#crdz" ]);
  } else {
    $pott = 0;
    my $ppos = 0;
    if($newc =~ /^p(\d)$/) { $ppos = $1; }
    while(@crdz > $ppos) {
      my $card = $crdz[-1];
      ($imgz[$posi[$#crdz]][5], $imgz[$zknr{substr($card, 0, 1)} - 1][$ztus{substr($card, 1, 1)}]) =
        ($imgz[$zknr{substr($card, 0, 1)} - 1][$ztus{substr($card, 1, 1)}], $imgz[$posi[$#crdz]][5]);
      ($lblz[$posi[$#crdz]][5], $lblz[$zknr{substr($card, 0, 1)} - 1][$ztus{substr($card, 1, 1)}]) =
        ($lblz[$zknr{substr($card, 0, 1)} - 1][$ztus{substr($card, 1, 1)}], $lblz[$posi[$#crdz]][5]);
      $lblz[$posi[$#crdz]][5]->grid(-row => 5, -column => $posi[$#crdz], -sticky => 'n');
      $lblz[$zknr{substr($card, 0, 1)} - 1][$ztus{substr($card, 1, 1)}]->grid(-row => $ztus{substr($card, 1, 1)}, -column => ($zknr{substr($card, 0, 1)} - 1), -sticky => 'n');
      $lblz[$zknr{substr($card, 0, 1)} - 1][$ztus{substr($card, 1, 1)}]->bind('<Button-1>' => [ \&HndlCrdz, $card ]);
      pop(@crdz);
    }
  }
  CkStats();
}

sub UpdtPott {
  my $lorb = shift() || return(); # lil  or big
  my $porm = shift() || return(); # plus or minus
  my $ppot = $pott;
  if($lorb eq 'lil') {
    if($porm eq '+') { $pott += $lilb; }
    else             { $pott -= $lilb; }
  } else {
    if($porm eq '+') { $pott += $bigb; }
    else             { $pott -= $bigb; }
  }
  CkStats() if($ppot != $pott);
}

sub DrawCrdz {
  for($colm = 0; $colm < @rnkz; $colm++) {
    my $rank = $rnkz[$colm];
    my $imag; my $labl;
    if     ($colm == 0) {
      $imag = $mwin->Photo(-file => "$ipth/o1$sufx");
      $labl = $fram->Label(-image => $imag,  -background => '#03071B', -foreground => '#88B8D0')->grid(-row => 0, -column => $colm, -sticky => 'n');
      $labl->bind('<Button-1>' => [ \&HndlCrdz, 'o1' ]);
    } elsif($colm == 1) { # - buttons
      my $bfrm = $fram->Frame(-background => '#03071B')->grid(-row => 0, -column => $colm, -sticky => 'n');
      $bfrm->Label(-text => 'Lil:',  -background => '#03071B', -foreground => '#88B8D0')->grid(-row => 0, -column => 0, -sticky => 'n');
      $bfrm->Button(-text => '-',  -background => '#03071B', -foreground => '#88B8D0', -command => [ \&UpdtPott, 'lil', '-' ])->grid(-row => 1, -column => 0, -sticky => 'n');
      $bfrm->Label(-text => 'Big:',  -background => '#03071B', -foreground => '#88B8D0')->grid(-row => 2, -column => 0, -sticky => 'n');
      $bfrm->Button(-text => '-',  -background => '#03071B', -foreground => '#88B8D0', -command => [ \&UpdtPott, 'big', '-' ])->grid(-row => 3, -column => 0, -sticky => 'n');
    } elsif($colm == 2) { # lil && big blinds
      my $bfrm = $fram->Frame(-background => '#03071B')->grid(-row => 0, -column => $colm, -sticky => 'n');
      $bfrm->Label(-text => 'Lil:',  -background => '#03071B', -foreground => '#88B8D0')->grid(-row => 0, -column => 0, -sticky => 'n');
      $bfrm->Entry(-width => 3, -textvariable => \$lilb                                )->grid(-row => 1, -column => 0, -sticky => 'n');
      $bfrm->Label(-text => 'Big:',  -background => '#03071B', -foreground => '#88B8D0')->grid(-row => 2, -column => 0, -sticky => 'n');
      $bfrm->Entry(-width => 3, -textvariable => \$bigb                                )->grid(-row => 3, -column => 0, -sticky => 'n');
    } elsif($colm == 3) { # + buttons
      my $bfrm = $fram->Frame(-background => '#03071B')->grid(-row => 0, -column => $colm, -sticky => 'n');
      $bfrm->Label(-text => 'Lil:',  -background => '#03071B', -foreground => '#88B8D0')->grid(-row => 0, -column => 0, -sticky => 'n');
      $bfrm->Button(-text => '+',  -background => '#03071B', -foreground => '#88B8D0', -command => [ \&UpdtPott, 'lil', '+' ])->grid(-row => 1, -column => 0, -sticky => 'n');
      $bfrm->Label(-text => 'Big:',  -background => '#03071B', -foreground => '#88B8D0')->grid(-row => 2, -column => 0, -sticky => 'n');
      $bfrm->Button(-text => '+',  -background => '#03071B', -foreground => '#88B8D0', -command => [ \&UpdtPott, 'big', '+' ])->grid(-row => 3, -column => 0, -sticky => 'n');
    } elsif($colm == 4) { # pot
      my $bfrm = $fram->Frame(-background => '#03071B')->grid(-row => 0, -column => $colm, -sticky => 'n');
      $labl = $bfrm->Label(-text => 'Pot:',  -background => '#03071B', -foreground => '#88B8D0')->grid(-row => 0, -column => 0, -sticky => 'n');
              $bfrm->Entry(-width => 3, -textvariable => \$pott                                )->grid(-row => 1, -column => 0, -sticky => 'n');
    } elsif($colm >  4) {
      $imag = $mwin->Photo(-file => "$ipth/o" . (14 - $colm) . $sufx);
#      $imag = $mwin->Thumbnail(-images => ["$ipth/o" . (14 - $colm) . ".bmp"]);
      $labl = $fram->Label(-image => $imag,  -background => '#03071B', -foreground => '#88B8D0')->grid(-row => 0, -column => $colm, -sticky => 'n');
      $labl->bind('<Button-1>' => [ \&HndlCrdz, 'o' . (14 - $colm) ]);
    } else {
      $imag = $mwin->Photo(-file => "$ipth/blnk$sufx");
      $labl = $fram->Label(-image => $imag,  -background => '#03071B', -foreground => '#88B8D0')->grid(-row => 0, -column => $colm, -sticky => 'n');
    }
    $imgz[$colm][0] = $imag;
    $lblz[$colm][0] = $labl;
    for($roww = 1; $roww <= @sutz; $roww++) {
      my $suit = $sutz[$roww - 1]; my $xist = 0;
      for(my $indx = 0; $indx < @crdz; $indx++) {
        if($crdz[$indx] eq "$rank$suit") { $xist = 1; last(); }
      }
      if($xist) {
        $imag = $mwin->Photo(-file => "$ipth/blnk$sufx");
        $labl = $fram->Label(-image => $imag,  -background => '#03071B', -foreground => '#88B8D0')->grid(-row => $roww, -column => $colm, -sticky => 'n');
      } else {
        $imag = $mwin->Photo(-file => "$ipth/$rank$suit$sufp$sufx");
        $labl = $fram->Label(-image => $imag,  -background => '#03071B', -foreground => '#88B8D0')->grid(-row => $roww, -column => $colm, -sticky => 'n');
        $labl->bind('<Button-1>' => [ \&HndlCrdz, "$rank$suit" ]);
      }
      $imgz[$colm][$roww] = $imag;
      $lblz[$colm][$roww] = $labl;
    }
    if     ($colm == 0) {
      $imag = $mwin->Photo(-file => "$ipth/o$oppo$sufx");
      $labl = $fram->Label(-image => $imag,  -background => '#03071B', -foreground => '#88B8D0')->grid(-row => 5, -column => $colm, -sticky => 'n');
      $labl->bind('<Button-1>' => [ \&HndlCrdz, 'o0' ]);
    } else {
      $imag = $mwin->Photo(-file => "$ipth/blnk$sufx");
      $labl = $fram->Label(-image => $imag,  -background => '#03071B', -foreground => '#88B8D0')->grid(-row => 5, -column => $colm, -sticky => 'n');
    }
    $imgz[$colm][5] = $imag;
    $lblz[$colm][5] = $labl;
    if($szmd) {
      if     ($colm ==  0) {
        $labl = $fram->Label(-text         => 'oppo:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -sticky => 'n');
      } elsif($colm ==  1) {
        $labl = $fram->Label(-textvariable => \$oppo,  -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -sticky => 'n');
      } elsif($colm ==  2) {
        $labl = $fram->Label(-text         => 'hole:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -sticky => 'n');
      } elsif($colm ==  3) {
        $labl = $fram->Label(-textvariable => \$shrt,  -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -sticky => 'n');
      } elsif($colm ==  5) {
        $labl = $fram->Label(-text         => 'flop:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -sticky => 'n');
      } elsif($colm ==  6) {
        $labl = $fram->Label(-textvariable => \$shfl,  -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -sticky => 'n');
      } elsif($colm ==  8) {
        $labl = $fram->Label(-text         => 'turn:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -sticky => 'n');
      } elsif($colm ==  9) {
        $labl = $fram->Label(-textvariable => \$shtr,  -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -sticky => 'n');
      } elsif($colm == 10) {
        $labl = $fram->Label(-text         => 'rivr:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -sticky => 'n');
      } elsif($colm == 11) {
        $labl = $fram->Label(-textvariable => \$shrv,  -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -sticky => 'n');
      }
      $lblz[$colm][6] = $labl;
      if     ($colm ==  0) {
        $labl = $fram->Label(-text         => 'wins:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 7, -column => $colm, -sticky => 'n');
      } elsif($colm ==  1) {
        $labl = $fram->Label(-textvariable => \$wins,  -background => '#03071B', -foreground => '#D8F8F0', -font => "$fnt1")->grid(-row => 7, -column => $colm, -columnspan => 2, -sticky => 'n');
      } elsif($colm ==  3) {
        $labl = $fram->Label(-text         => 'ties:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 7, -column => $colm, -sticky => 'n');
      } elsif($colm ==  4) {
        $labl = $fram->Label(-textvariable => \$ties,  -background => '#03071B', -foreground => '#38B8F8', -font => "$fnt1")->grid(-row => 7, -column => $colm, -columnspan => 2, -sticky => 'n');
      } elsif($colm ==  6) {
        $labl = $fram->Label(-text         => 'loss:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 7, -column => $colm, -sticky => 'n');
      } elsif($colm ==  7) {
        $labl = $fram->Label(-textvariable => \$loss,  -background => '#03071B', -foreground => '#F83880', -font => "$fnt1")->grid(-row => 7, -column => $colm, -columnspan => 2, -sticky => 'n');
      } elsif($colm ==  9) {
        $labl = $fram->Label(-textvariable => \$ltxt,  -background => '#03071B', -foreground => '#88F8D0', -font => "$fnt0")->grid(-row => 7, -column => $colm, -columnspan => 4, -sticky => 'n');
      }
      $lblz[$colm][7] = $labl;
    } else {
      if     ($colm ==  0) {
        $labl = $fram->Label(-text         => 'oppo:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -columnspan => 2, -sticky => 'n');
      } elsif($colm ==  2) {
        $labl = $fram->Label(-textvariable => \$oppo,  -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -columnspan => 1, -sticky => 'n');
      } elsif($colm ==  3) {
        $labl = $fram->Label(-text         => 'hole:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -columnspan => 2, -sticky => 'n');
      } elsif($colm ==  5) {
        $labl = $fram->Label(-textvariable => \$shrt,  -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -columnspan => 3, -sticky => 'n');
      } elsif($colm ==  8) {
        $labl = $fram->Label(-text         => 'flop:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -columnspan => 2, -sticky => 'n');
      } elsif($colm == 10) {
        $labl = $fram->Label(-textvariable => \$shfl,  -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 6, -column => $colm, -columnspan => 3, -sticky => 'n');
      }
      $lblz[$colm][6] = $labl;
      if     ($colm ==  3) {
        $labl = $fram->Label(-text         => 'turn:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 7, -column => $colm, -columnspan => 2, -sticky => 'n');
      } elsif($colm ==  5) {
        $labl = $fram->Label(-textvariable => \$shtr,  -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 7, -column => $colm, -columnspan => 3, -sticky => 'n');
      } elsif($colm ==  8) {
        $labl = $fram->Label(-text         => 'rivr:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 7, -column => $colm, -columnspan => 2, -sticky => 'n');
      } elsif($colm == 10) {
        $labl = $fram->Label(-textvariable => \$shrv,  -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 7, -column => $colm, -columnspan => 3, -sticky => 'n');
      }
      $lblz[$colm][7] = $labl;
      if     ($colm ==  0) {
        $labl = $fram->Label(-text         => 'wins:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 8, -column => $colm, -columnspan => 2, -sticky => 'n');
      } elsif($colm ==  2) {
        $labl = $fram->Label(-textvariable => \$wins,  -background => '#03071B', -foreground => '#D8F8F0', -font => "$fnt1")->grid(-row => 8, -column => $colm, -columnspan => 4, -sticky => 'n');
      } elsif($colm ==  6) {
        $labl = $fram->Label(-text         => 'ties:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 8, -column => $colm, -columnspan => 2, -sticky => 'n');
      } elsif($colm ==  8) {
        $labl = $fram->Label(-textvariable => \$ties,  -background => '#03071B', -foreground => '#38B8F8', -font => "$fnt1")->grid(-row => 8, -column => $colm, -columnspan => 4, -sticky => 'n');
      }
      $lblz[$colm][8] = $labl;
      if     ($colm ==  0) {
        $labl = $fram->Label(-text         => 'loss:', -background => '#03071B', -foreground => '#88B8D0', -font => "$fnt0")->grid(-row => 9, -column => $colm, -columnspan => 2, -sticky => 'n');
      } elsif($colm ==  2) {
        $labl = $fram->Label(-textvariable => \$loss,  -background => '#03071B', -foreground => '#F83880', -font => "$fnt1")->grid(-row => 9, -column => $colm, -columnspan => 4, -sticky => 'n');
      } elsif($colm ==  7) {
        $labl = $fram->Label(-textvariable => \$ltxt,  -background => '#03071B', -foreground => '#88F8D0', -font => "$fnt0")->grid(-row => 9, -column => $colm, -columnspan => 6, -sticky => 'n');
      }
      $lblz[$colm][9] = $labl;
    }
  }
}

DrawCrdz();
MainLoop();
