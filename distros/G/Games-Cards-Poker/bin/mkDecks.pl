#!/usr/bin/perl -w
# 45V0PPk - mkDecks.pl created by Pip Stuart <Pip@CPAN.Org> to pre-
#   generate base-64 decks with each of the ShortHand holes removed.
# This code is distributed under the GNU General Public License (version 2).
use strict;
use Math::BaseCnv       qw(:all);
use Games::Cards::Poker qw(:all);
use Algorithm::ChooseSubsets;

my @deck = Deck(); my $pdex = shift() || 0;
my $choo = Algorithm::ChooseSubsets->new(\@deck, 2); my %data; my $choi;
push(@{$data{ShortHand(@{$choi})}}, [@{$choi}]) while($choi = $choo->next());
foreach(SortCards(keys(%data))) {
  @deck = Deck();
  print "  \"" unless($pdex);
  foreach my $card (@{$data{$_}[0]}) {
    print CardB64($card) unless($pdex);
    RemoveCard($card, \@deck);
  }
  print "\", " unless($pdex);
  printf("  \"%s\",\n", HandB64(@deck)) if($pdex);
}
