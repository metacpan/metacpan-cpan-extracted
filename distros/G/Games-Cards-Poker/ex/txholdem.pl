#!/usr/bin/perl
# 64JKFVEl:txholdem.pl crE8d by PipStuart <Pip@CPAN.Org> to gener8 Texas Hold'Em Poker hands for 10 players && print sorted results;
use strict;use warnings;use Games::Cards::Poker qw(:all);my $VERSION='0.0';my $d8VS='H65MA3CC';
my $board_size =    5; # number of cards to deal to the community board
my $players    =   10; # number of players to get hands dealt
my @holes      =   (); # player hole  data
my @board      =   (); # board (first 3 are flop, next turn, last river)
my @best_score =   (); # player score data
my @found      =   (); # list of players found with certain best scores
my @deck       = Shuffle(Deck());
my $winners    =  'P'; # list of indices of winning players
my $win_points =    0; # the awarded win_score (fractional if tied)
my $win_score  = 7462; # the lowest score that won the game
while($board_size--){push(@board, shift(@deck));}
printf("Board(    flop:%9s     turn: $board[3]     " .
       "river: $board[4]    )\n", join(' ', SortCards(@board[0..2])));
for(0..($players - 1)){ # Deal hands
  @{$holes[   $_]} = SortCards(shift(@deck), shift(@deck));
  $best_score[$_]  = HandScore(BestHand(@{$holes[$_]}, @board));}
for(reverse(sort { $a <=> $b } @best_score)){ # print hands worst to best
  for my $player (0..($players - 1)){ # match score back to player(s)
    if((@found < $player || !$found[$player]) && defined($best_score[$player]) &&
                                                         $best_score[$player]  == $_ ){
      $found[$player]++;
      printf("Player$player: @{$holes[$player]}  ShortHand: %-4s",
                   ShortHand(@{$holes[$player]}));
      printf("  BestHand: %14s",
           join(' ', SortCards(BestHand(@{$holes[$player]}, @board))));
      printf("        Score: %4d\n", $best_score[$player]);}}
  $win_score = $_;} # last scores should be best (i.e., lowest) and win
for(0..($players - 1)){ # build winners list and count point split
  if($win_score == $best_score[$_]){$winners .= "$_,"; $win_points++;}}
chop($winners); # strip the extra comma from the end
if($win_points){$win_points = (1.0 / $win_points);}
else           {$win_points =  1.0;               }
printf("%-7s:     awarded WinPoints: %1.4f                " .
  "for lowest Score: %4d\n  HandName:%s  VerboseHandName:%s\n", $winners,
  $win_points, $win_score,  HandName($win_score),
                                         VerboseHandName($win_score));
