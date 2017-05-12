#!/usr/bin/perl
use strict;
use warnings;
use List::NSect;
use List::Util qw{shuffle};

=head1 NAME

List-NSect-card-dealer.pl - List::NSect Card Dealer

=head1 SEE ALSO

L<Games::Cards>

=cut

$|          = 1;
my $players = shift || 4;
my @deck    = ();
my $sort    = 1;

#build the deck

foreach my $suit (qw{C D H S}) {
  foreach my $card (qw{2 3 4 5 6 7 8 9 10 J Q K A}) {
    push @deck, {card=>$card, suit=>$suit, sort=>$sort++};
  }
}

#shuffle

my @shuffle=shuffle @deck;

#List::Util::shuffle is MUCH better than in real life.

#TODO: cut

#build the kitty first as nsect would keep dealing the extras like for War or Crazy Eights

my @kitty=();
while (@shuffle % $players) {
  push @kitty, pop @shuffle;
}

#deal the hands

my @hands=nsect($players, @shuffle);

#Note: nsect did not "deal" the cards since it gave the first player all of thier cards then the second player and so forth.

#play

my $i=1;
foreach my $hand (@hands) {
  printf "%s: %s\n", $i++,
    join(", ", 
      map {sprintf("%s%s", $_->{"card"}, $_->{"suit"})}
        sort {$a->{"sort"} <=> $b->{"sort"}}
          @$hand);
}

printf "Kitty: %s\n",
   join(", ",
      map {sprintf("%s%s", $_->{"card"}, $_->{"suit"})}
        sort {$a->{"sort"} <=> $b->{"sort"}}
          @kitty);
