#!/usr/bin/perl -w
# 43KNlxM - tstPoker.pl created by Pip Stuart <Pip@CPAN.Org> to generate
#   test runs of Texas Hold'Em poker hands && print out the results.
# USAGE: `perl tstPoker.pl <NumberOfRounds> <NumberOfPlayersDealt>`
# This code is distributed under the GNU General Public License (version 2).
use strict;
use Math::BaseCnv       qw(:all);
use Games::Cards::Poker qw(:all);

my $nmax = shift ||  1; my $nndx; my $indx;
my $nump = shift || 10; # number of players
my $prnt = shift; $prnt = 1 unless(defined($prnt));
my @hndz = (); my @scor = (); my @bstz = (); my @best = (); my @tscr = ();
my @cpkt = (); my %pwin = (); my $tops =  0; my @deck = (); my @bord = ();
for(my $nndx = 0; $nndx < $nmax; $nndx++) {
  @hndz = (); @scor = (); @bstz = (); @cpkt = (); @bord = ();
  @deck = Shuffle(Deck());
  foreach(0..4) { push(@bord, shift(@deck)); }
  if($prnt) {
    printf("Test#: %7d                   ", $nndx);
    printf("Board( flop:%9s  turn: $bord[3]  rivr: $bord[4] )\n",
      join(' ', SortCards(@bord[0..2])));
  }
  foreach $indx (0..($nump - 1)) { # Deal hands
    @{$hndz[$indx]} = SortCards(shift(@deck), shift(@deck));
      $bstz[$indx]  = ScoreHand(BestHand(@{$hndz[$indx]}, @bord));
  }
  @scor = @bstz;
  @tscr = sort { $a <=> $b } @scor;
  if($prnt) {
    my @foun = ();
    foreach(reverse(@tscr)) { # print hands worst to best
      foreach $indx (0..($nump - 1)) { # Calculate best hands
        if((@foun < $indx || !$foun[$indx]) && 
           ($scor[$indx] == $_)) {
          $foun[$indx]++;
          printf("Player$indx: @{$hndz[$indx]}  ShortHand: %-4s", ShortHand(@{$hndz[$indx]}));
          printf("  BestHand: %14s", join(' ', SortCards(BestHand(@{$hndz[$indx]}, @bord)))) if($prnt);
          printf("        Score: %4d\n", $scor[$indx]);
        }
      }
    }
  }
  $tops = $tscr[0]; # Top base Score
  my $frac = 0; my $wnrz = 'P';
  for($indx = 0; $indx < @scor; $indx++) {
    if($tops == $scor[$indx]) {
      $wnrz .= ','   if($prnt && $frac);
      $wnrz .= $indx if($prnt);
      $pwin{$hndz[$indx]}++;
      $frac++;
    }
  }
  $frac = 0;
  for($indx = 0; $indx < @scor; $indx++) {
    $frac++ if($tops == $scor[$indx]);
  }
  $frac = 1 unless($frac);
  $frac = (1.0 / $frac);
  printf("%-7s:     awarded WinScore: %1.4f             for lowest HandScore: %4d\n\n", $wnrz, $frac, $tops) if($prnt);
}
