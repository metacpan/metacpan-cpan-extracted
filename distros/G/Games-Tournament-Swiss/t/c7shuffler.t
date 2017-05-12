#!usr/bin/perl

# 3-to-10-player bracket c7shuffler testing

use lib qw/t lib/;

use strict;
use warnings;
use Test::More;

BEGIN {
    $Games::Tournament::Swiss::Config::firstround = 1;
    @Games::Tournament::Swiss::Config::roles      = qw/White Black/;
    %Games::Tournament::Swiss::Config::scores      = (
    Win => 1, Draw => 0.5, Loss => 0, Absence => 0, Bye => 1 );
    $Games::Tournament::Swiss::Config::algorithm  =
      'Games::Tournament::Swiss::Procedure::Dummy';
}
use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Swiss::Bracket;

my $one = Games::Tournament::Contestant::Swiss->new(
    pairingNumber => 1, name => 'Ray', title  => 'Expert', rating => 100,);
my $two = Games::Tournament::Contestant::Swiss->new(
    pairingNumber => 2, name => 'Red', title  => 'Expert', rating => 80,);
my $three = Games::Tournament::Contestant::Swiss->new(
    pairingNumber => 3, name => 'Reg', score => 0, title  => 'Expert',
    rating => '50',);
my $four = Games::Tournament::Contestant::Swiss->new(
    pairingNumber => 4, name   => 'Rob', title  => 'Novice', rating => 25,);
my $five = Games::Tournament::Contestant::Swiss->new(
    pairingNumber => 5, name => 'Rod', score => 0, title => 'Novice',
    rating => 3,);
my $six = Games::Tournament::Contestant::Swiss->new(
    pairingNumber => 6, name => 'Rog', score => 0, title  => 'Novice',
    rating => 2,);
my $seven = Games::Tournament::Contestant::Swiss->new(
    pairingNumber => 7, name  => 'Ron', score => 0, title => 'Novice',
    rating => 1,);
my $eight = Games::Tournament::Contestant::Swiss->new(
    pairingNumber => 8, name  => 'Ros', score => 0, title => 'Novice',);
my $nine = Games::Tournament::Contestant::Swiss->new(
    pairingNumber    => 9, name  => 'Roy', score => 0, title => 'Novice',);
my $ten = Games::Tournament::Contestant::Swiss->new(
    pairingNumber    => 10, name  => 'Ruy', score => 0, title => 'Novice',);

my $b2 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [ $one, $two, ]);

my $b3 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [ $one, $two, $three, ]);

my $b4 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [ $one, $two, $three, $four ]);

my $b5 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [ $one, $two, $three, $four, $five ]);

my $b6 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [ $one, $two, $three, $four, $five, $six ]);

my $b7 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [$one,$two,$three,$four,$five,$six,$seven]);

my $b8 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [$one,$two,$three,$four,$five,$six,$seven,$eight]);

my $b9 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [$one,$two,$three,$four,$five,$six,$seven,$eight,$nine]);

my $b10 = Games::Tournament::Swiss::Bracket->new(
    score   => 0, members => [$one,$two,$three,$four,$five,$six,$seven,$eight,$nine,$ten]);

my $shuffler = sub {
		my $bracket = shift;
		my $position = shift;
		$bracket->resetS12;
		return sub {
			my @s2 = $bracket->c7shuffler($position,undef);
			$bracket->s2(\@s2) if @s2;
			return \@s2;
			}
		};

my $next2 = $shuffler->($b2,0);
my $next3 = $shuffler->($b3,1);
my $next4 = $shuffler->($b4,1);
my $next5 = $shuffler->($b5,2);
my $next6 = $shuffler->($b6,2);
my $next7 = $shuffler->($b7,3);
my $next8 = $shuffler->($b8,3);
my $next9 = $shuffler->($b9,4);
my $next10 = $shuffler->($b10,4);

my @tests = (
[ $next2->(), [], 'shuffle 2'],
[ $next3->(), [$three,$two],	'shuffle 3'],
[ $next3->(), [],	'shuffle 3 last'],
[ $next4->(), [$four,$three],	'shuffle 4'],
[ $next4->(), [],	'shuffle 4 last'],
[ $next5->(), [$three,$five,$four],	'shuffle 5a'],
[ $next5->(), [$four,$three,$five],	'shuffle 5b'],
[ $next5->(), [$four,$five,$three],	'shuffle 5c'],
[ $next5->(), [$five,$three,$four],	'shuffle 5d'],
[ $next5->(), [$five,$four,$three],	'shuffle 5e'],
[ $next5->(), [],	'shuffle 5 last'],
[ $next6->(), [$four,$six,$five],	'shuffle 6a'],
[ $next6->(), [$five,$four,$six],	'shuffle 6b'],
[ $next6->(), [$five,$six,$four],	'shuffle 6eight'],
[ $next6->(), [$six,$four,$five],	'shuffle 6d'],
[ $next6->(), [$six,$five,$four],	'shuffle 6e'],
[ $next6->(), [],	'shuffle 6 last'],
[ $next7->(), [$four,$five,$seven,$six], 'shuffle 7a'],
[ $next7->(), [$four,$six,$five,$seven], 'shuffle 7b'],
[ $next7->(), [$four,$six,$seven,$five], 'shuffle 7c'],
[ $next7->(), [$four,$seven,$five,$six], 'shuffle 7d'],
[ $next7->(), [$four,$seven,$six,$five], 'shuffle 7e'],
[ $next7->(), [$five,$four,$six,$seven], 'shuffle 7f'],
[ $next7->(), [$five,$four,$seven,$six], 'shuffle 7g'],
[ $next7->(), [$five,$six,$four,$seven], 'shuffle 7h'],
[ $next7->(), [$five,$six,$seven,$four], 'shuffle 7i'],
[ $next7->(), [$five,$seven,$four,$six], 'shuffle 7j'],
[ $next7->(), [$five,$seven,$six,$four], 'shuffle 7k'],
[ $next7->(), [$six,$four,$five,$seven], 'shuffle 7l'],
[ $next7->(), [$six,$four,$seven,$five], 'shuffle 7m'],
[ $next7->(), [$six,$five,$four,$seven], 'shuffle 7n'],
[ $next7->(), [$six,$five,$seven,$four], 'shuffle 7o'],
[ $next7->(), [$six,$seven,$four,$five], 'shuffle 7p'],
[ $next7->(), [$six,$seven,$five,$four], 'shuffle 7q'],
[ $next7->(), [$seven,$four,$five,$six], 'shuffle 7r'],
[ $next7->(), [$seven,$four,$six,$five], 'shuffle 7s'],
[ $next7->(), [$seven,$five,$four,$six], 'shuffle 7t'],
[ $next7->(), [$seven,$five,$six,$four], 'shuffle 7u'],
[ $next7->(), [$seven,$six,$four,$five], 'shuffle 7v'],
[ $next7->(), [$seven,$six,$five,$four], 'shuffle 7w'],
[ $next7->(), [], 'shuffle 7 last'],

[ $next8->(), [$five,$six,$eight,$seven], 'shuffle 8a'],
[ $next8->(), [$five,$seven,$six,$eight], 'shuffle 8b'],
[ $next8->(), [$five,$seven,$eight,$six], 'shuffle 8c'],
[ $next8->(), [$five,$eight,$six,$seven], 'shuffle 8d'],
[ $next8->(), [$five,$eight,$seven,$six], 'shuffle 8e'],
[ $next8->(), [$six,$five,$seven,$eight], 'shuffle 8f'],
[ $next8->(), [$six,$five,$eight,$seven], 'shuffle 8g'],
[ $next8->(), [$six,$seven,$five,$eight], 'shuffle 8h'],
[ $next8->(), [$six,$seven,$eight,$five], 'shuffle 8i'],
[ $next8->(), [$six,$eight,$five,$seven], 'shuffle 8j'],
[ $next8->(), [$six,$eight,$seven,$five], 'shuffle 8k'],
[ $next8->(), [$seven,$five,$six,$eight], 'shuffle 8l'],
[ $next8->(), [$seven,$five,$eight,$six], 'shuffle 8m'],
[ $next8->(), [$seven,$six,$five,$eight], 'shuffle 8n'],
[ $next8->(), [$seven,$six,$eight,$five], 'shuffle 8o'],
[ $next8->(), [$seven,$eight,$five,$six], 'shuffle 8p'],
[ $next8->(), [$seven,$eight,$six,$five], 'shuffle 8q'],
[ $next8->(), [$eight,$five,$six,$seven], 'shuffle 8r'],
[ $next8->(), [$eight,$five,$seven,$six], 'shuffle 8s'],
[ $next8->(), [$eight,$six,$five,$seven], 'shuffle 8t'],
[ $next8->(), [$eight,$six,$seven,$five], 'shuffle 8u'],
[ $next8->(), [$eight,$seven,$five,$six], 'shuffle 8v'],
[ $next8->(), [$eight,$seven,$six,$five], 'shuffle 8w'],
[ $next8->(), [], 'shuffle 8 last'],

[ $next9->(), [$five,$six,$seven,$nine,$eight], 'shuffle9a'],
[ $next9->(), [$five,$six,$eight,$seven,$nine], 'shuffle9b'],
[ $next9->(), [$five,$six,$eight,$nine,$seven], 'shuffle9c'],
[ $next9->(), [$five,$six,$nine,$seven,$eight], 'shuffle9d'],
[ $next9->(), [$five,$six,$nine,$eight,$seven], 'shuffle9e'],
[ $next9->(), [$five,$seven,$six,$eight,$nine], 'shuffle9e'],
[ $next9->(), [$five,$seven,$six,$nine,$eight], 'shuffle9f'],
[ $next9->(), [$five,$seven,$eight,$six,$nine], 'shuffle9g'],
[ $next9->(), [$five,$seven,$eight,$nine,$six], 'shuffle9h'],
[ $next9->(), [$five,$seven,$nine,$six,$eight], 'shuffle9i'],
[ $next9->(), [$five,$seven,$nine,$eight,$six], 'shuffle9j'],
[ $next9->(), [$five,$eight,$six,$seven,$nine], 'shuffle9k'],
[ $next9->(), [$five,$eight,$six,$nine,$seven], 'shuffle9l'],
[ $next9->(), [$five,$eight,$seven,$six,$nine], 'shuffle9m'],
[ $next9->(), [$five,$eight,$seven,$nine,$six], 'shuffle9n'],
[ $next9->(), [$five,$eight,$nine,$six,$seven], 'shuffle9o'],
[ $next9->(), [$five,$eight,$nine,$seven,$six], 'shuffle9p'],
[ $next9->(), [$five,$nine,$six,$seven,$eight], 'shuffle9q'],
[ $next9->(), [$five,$nine,$six,$eight,$seven], 'shuffle9r'],
[ $next9->(), [$five,$nine,$seven,$six,$eight], 'shuffle9s'],
[ $next9->(), [$five,$nine,$seven,$eight,$six], 'shuffle9t'],
[ $next9->(), [$five,$nine,$eight,$six,$seven], 'shuffle9u'],
[ $next9->(), [$five,$nine,$eight,$seven,$six], 'shuffle9v'],
[ $next9->(), [$six,$five,$seven,$eight,$nine], 'shuffle9w'],
[ $next9->(), [$six,$five,$seven,$nine,$eight], 'shuffle9x'],
[ $next9->(), [$six,$five,$eight,$seven,$nine], 'shuffle9y'],
[ $next9->(), [$six,$five,$eight,$nine,$seven], 'shuffle9z'],
[ $next9->(), [$six,$five,$nine,$seven,$eight], 'shuffle9aa'],
[ $next9->(), [$six,$five,$nine,$eight,$seven], 'shuffle9ab'],
[ $next9->(), [$six,$seven,$five,$eight,$nine], 'shuffle9ac'],
[ $next9->(), [$six,$seven,$five,$nine,$eight], 'shuffle9ad'],
[ $next9->(), [$six,$seven,$eight,$five,$nine], 'shuffle9ae'],
[ $next9->(), [$six,$seven,$eight,$nine,$five], 'shuffle9af'],
[ $next9->(), [$six,$seven,$nine,$five,$eight], 'shuffle9ag'],
[ $next9->(), [$six,$seven,$nine,$eight,$five], 'shuffle9ah'],
[ $next9->(), [$six,$eight,$five,$seven,$nine], 'shuffle9ai'],
[ $next9->(), [$six,$eight,$five,$nine,$seven], 'shuffle9aj'],
[ $next9->(), [$six,$eight,$seven,$five,$nine], 'shuffle9ak'],
[ $next9->(), [$six,$eight,$seven,$nine,$five], 'shuffle9al'],
[ $next9->(), [$six,$eight,$nine,$five,$seven], 'shuffle9am'],
[ $next9->(), [$six,$eight,$nine,$seven,$five], 'shuffle9an'],
[ $next9->(), [$six,$nine,$five,$seven,$eight], 'shuffle9ao'],
[ $next9->(), [$six,$nine,$five,$eight,$seven], 'shuffle9ap'],
[ $next9->(), [$six,$nine,$seven,$five,$eight], 'shuffle9aq'],
[ $next9->(), [$six,$nine,$seven,$eight,$five], 'shuffle9ar'],
[ $next9->(), [$six,$nine,$eight,$five,$seven], 'shuffle9as'],
[ $next9->(), [$six,$nine,$eight,$seven,$five], 'shuffle9at'],
[ $next9->(), [$seven,$five,$six,$eight,$nine], 'shuffle9au'],
[ $next9->(), [$seven,$five,$six,$nine,$eight], 'shuffle9av'],
[ $next9->(), [$seven,$five,$eight,$six,$nine], 'shuffle9aw'],
[ $next9->(), [$seven,$five,$eight,$nine,$six], 'shuffle9ay'],
[ $next9->(), [$seven,$five,$nine,$six,$eight], 'shuffle9az'],
[ $next9->(), [$seven,$five,$nine,$eight,$six], 'shuffle9ba'],
[ $next9->(), [$seven,$six,$five,$eight,$nine], 'shuffle9bb'],
[ $next9->(), [$seven,$six,$five,$nine,$eight], 'shuffle9bb'],
[ $next9->(), [$seven,$six,$eight,$five,$nine], 'shuffle9bc'],
[ $next9->(), [$seven,$six,$eight,$nine,$five], 'shuffle9bd'],
[ $next9->(), [$seven,$six,$nine,$five,$eight], 'shuffle9be'],
[ $next9->(), [$seven,$six,$nine,$eight,$five], 'shuffle9bf'],
[ $next9->(), [$seven,$eight,$five,$six,$nine], 'shuffle9bg'],
[ $next9->(), [$seven,$eight,$five,$nine,$six], 'shuffle9bh'],
[ $next9->(), [$seven,$eight,$six,$five,$nine], 'shuffle9bi'],
[ $next9->(), [$seven,$eight,$six,$nine,$five], 'shuffle9bj'],
[ $next9->(), [$seven,$eight,$nine,$five,$six], 'shuffle9bk'],
[ $next9->(), [$seven,$eight,$nine,$six,$five], 'shuffle9bl'],
[ $next9->(), [$seven,$nine,$five,$six,$eight], 'shuffle9bm'],
[ $next9->(), [$seven,$nine,$five,$eight,$six], 'shuffle9bn'],
[ $next9->(), [$seven,$nine,$six,$five,$eight], 'shuffle9bo'],
[ $next9->(), [$seven,$nine,$six,$eight,$five], 'shuffle9bp'],
[ $next9->(), [$seven,$nine,$eight,$five,$six], 'shuffle9bq'],
[ $next9->(), [$seven,$nine,$eight,$six,$five], 'shuffle9br'],
[ $next9->(), [$eight,$five,$six,$seven,$nine], 'shuffle9bs'],
[ $next9->(), [$eight,$five,$six,$nine,$seven], 'shuffle9bt'],
[ $next9->(), [$eight,$five,$seven,$six,$nine], 'shuffle9bu'],
[ $next9->(), [$eight,$five,$seven,$nine,$six], 'shuffle9bv'],
[ $next9->(), [$eight,$five,$nine,$six,$seven], 'shuffle9bw'],
[ $next9->(), [$eight,$five,$nine,$seven,$six], 'shuffle9bx'],
[ $next9->(), [$eight,$six,$five,$seven,$nine], 'shuffle9by'],
[ $next9->(), [$eight,$six,$five,$nine,$seven], 'shuffle9bz'],
[ $next9->(), [$eight,$six,$seven,$five,$nine], 'shuffle9bz'],
[ $next9->(), [$eight,$six,$seven,$nine,$five], 'shuffle9ca'],
[ $next9->(), [$eight,$six,$nine,$five,$seven], 'shuffle9cb'],
[ $next9->(), [$eight,$six,$nine,$seven,$five], 'shuffle9cc'],
[ $next9->(), [$eight,$seven,$five,$six,$nine], 'shuffle9cd'],
[ $next9->(), [$eight,$seven,$five,$nine,$six], 'shuffle9ce'],
[ $next9->(), [$eight,$seven,$six,$five,$nine], 'shuffle9cf'],
[ $next9->(), [$eight,$seven,$six,$nine,$five], 'shuffle9cg'],
[ $next9->(), [$eight,$seven,$nine,$five,$six], 'shuffle9ch'],
[ $next9->(), [$eight,$seven,$nine,$six,$five], 'shuffle9ci'],
[ $next9->(), [$eight,$nine,$five,$six,$seven], 'shuffle9cj'],
[ $next9->(), [$eight,$nine,$five,$seven,$six], 'shuffle9ck'],
[ $next9->(), [$eight,$nine,$six,$five,$seven], 'shuffle9cl'],
[ $next9->(), [$eight,$nine,$six,$seven,$five], 'shuffle9cm'],
[ $next9->(), [$eight,$nine,$seven,$five,$six], 'shuffle9cn'],
[ $next9->(), [$eight,$nine,$seven,$six,$five], 'shuffle9co'],
[ $next9->(), [$nine,$five,$six,$seven,$eight], 'shuffle9cp'],
[ $next9->(), [$nine,$five,$six,$eight,$seven], 'shuffle9cq'],
[ $next9->(), [$nine,$five,$seven,$six,$eight], 'shuffle9cr'],
[ $next9->(), [$nine,$five,$seven,$eight,$six], 'shuffle9cs'],
[ $next9->(), [$nine,$five,$eight,$six,$seven], 'shuffle9ct'],
[ $next9->(), [$nine,$five,$eight,$seven,$six], 'shuffle9cu'],
[ $next9->(), [$nine,$six,$five,$seven,$eight], 'shuffle9cv'],
[ $next9->(), [$nine,$six,$five,$eight,$seven], 'shuffle9cw'],
[ $next9->(), [$nine,$six,$seven,$five,$eight], 'shuffle9cy'],
[ $next9->(), [$nine,$six,$seven,$eight,$five], 'shuffle9cz'],
[ $next9->(), [$nine,$six,$eight,$five,$seven], 'shuffle9da'],
[ $next9->(), [$nine,$six,$eight,$seven,$five], 'shuffle9db'],
[ $next9->(), [$nine,$seven,$five,$six,$eight], 'shuffle9dc'],
[ $next9->(), [$nine,$seven,$five,$eight,$six], 'shuffle9dd'],
[ $next9->(), [$nine,$seven,$six,$five,$eight], 'shuffle9de'],
[ $next9->(), [$nine,$seven,$six,$eight,$five], 'shuffle9df'],
[ $next9->(), [$nine,$seven,$eight,$five,$six], 'shuffle9dg'],
[ $next9->(), [$nine,$seven,$eight,$six,$five], 'shuffle9dh'],
[ $next9->(), [$nine,$eight,$five,$six,$seven], 'shuffle9di'],
[ $next9->(), [$nine,$eight,$five,$seven,$six], 'shuffle9dj'],
[ $next9->(), [$nine,$eight,$six,$five,$seven], 'shuffle9dk'],
[ $next9->(), [$nine,$eight,$six,$seven,$five], 'shuffle9dl'],
[ $next9->(), [$nine,$eight,$seven,$five,$six], 'shuffle9dm'],
[ $next9->(), [$nine,$eight,$seven,$six,$five], 'shuffle9dn'],
[ $next9->(), [], 'shuffle9 last'],

[ $next10->(), [$six,$seven,$eight,$ten,$nine], 'shuffle10a'],
[ $next10->(), [$six,$seven,$nine,$eight,$ten], 'shuffle10b'],
[ $next10->(), [$six,$seven,$nine,$ten,$eight], 'shuffle10c'],
[ $next10->(), [$six,$seven,$ten,$eight,$nine], 'shuffle10d'],
[ $next10->(), [$six,$seven,$ten,$nine,$eight], 'shuffle10e'],
[ $next10->(), [$six,$eight,$seven,$nine,$ten], 'shuffle10f'],
[ $next10->(), [$six,$eight,$seven,$ten,$nine], 'shuffle10g'],
[ $next10->(), [$six,$eight,$nine,$seven,$ten], 'shuffle10h'],
[ $next10->(), [$six,$eight,$nine,$ten,$seven], 'shuffle10i'],
[ $next10->(), [$six,$eight,$ten,$seven,$nine], 'shuffle10j'],
[ $next10->(), [$six,$eight,$ten,$nine,$seven], 'shuffle10k'],
[ $next10->(), [$six,$nine,$seven,$eight,$ten], 'shuffle10l'],
[ $next10->(), [$six,$nine,$seven,$ten,$eight], 'shuffle10m'],
[ $next10->(), [$six,$nine,$eight,$seven,$ten], 'shuffle10n'],
[ $next10->(), [$six,$nine,$eight,$ten,$seven], 'shuffle10o'],
[ $next10->(), [$six,$nine,$ten,$seven,$eight], 'shuffle10p'],
[ $next10->(), [$six,$nine,$ten,$eight,$seven], 'shuffle10q'],
[ $next10->(), [$six,$ten,$seven,$eight,$nine], 'shuffle10r'],
[ $next10->(), [$six,$ten,$seven,$nine,$eight], 'shuffle10s'],
[ $next10->(), [$six,$ten,$eight,$seven,$nine], 'shuffle10t'],
[ $next10->(), [$six,$ten,$eight,$nine,$seven], 'shuffle10u'],
[ $next10->(), [$six,$ten,$nine,$seven,$eight], 'shuffle10v'],
[ $next10->(), [$six,$ten,$nine,$eight,$seven], 'shuffle10w'],
[ $next10->(), [$seven,$six,$eight,$nine,$ten], 'shuffle10x'],
[ $next10->(), [$seven,$six,$eight,$ten,$nine], 'shuffle10y'],
[ $next10->(), [$seven,$six,$nine,$eight,$ten], 'shuffle10z'],
[ $next10->(), [$seven,$six,$nine,$ten,$eight], 'shuffle10aa'],
[ $next10->(), [$seven,$six,$ten,$eight,$nine], 'shuffle10ab'],
[ $next10->(), [$seven,$six,$ten,$nine,$eight], 'shuffle10ac'],
[ $next10->(), [$seven,$eight,$six,$nine,$ten], 'shuffle10ad'],
[ $next10->(), [$seven,$eight,$six,$ten,$nine], 'shuffle10ae'],
[ $next10->(), [$seven,$eight,$nine,$six,$ten], 'shuffle10af'],
[ $next10->(), [$seven,$eight,$nine,$ten,$six], 'shuffle10ag'],
[ $next10->(), [$seven,$eight,$ten,$six,$nine], 'shuffle10ah'],
[ $next10->(), [$seven,$eight,$ten,$nine,$six], 'shuffle10ai'],
[ $next10->(), [$seven,$nine,$six,$eight,$ten], 'shuffle10aj'],
[ $next10->(), [$seven,$nine,$six,$ten,$eight], 'shuffle10ak'],
[ $next10->(), [$seven,$nine,$eight,$six,$ten], 'shuffle10al'],
[ $next10->(), [$seven,$nine,$eight,$ten,$six], 'shuffle10am'],
[ $next10->(), [$seven,$nine,$ten,$six,$eight], 'shuffle10an'],
[ $next10->(), [$seven,$nine,$ten,$eight,$six], 'shuffle10ao'],
[ $next10->(), [$seven,$ten,$six,$eight,$nine], 'shuffle10ap'],
[ $next10->(), [$seven,$ten,$six,$nine,$eight], 'shuffle10aq'],
[ $next10->(), [$seven,$ten,$eight,$six,$nine], 'shuffle10ar'],
[ $next10->(), [$seven,$ten,$eight,$nine,$six], 'shuffle10as'],
[ $next10->(), [$seven,$ten,$nine,$six,$eight], 'shuffle10at'],
[ $next10->(), [$seven,$ten,$nine,$eight,$six], 'shuffle10au'],
[ $next10->(), [$eight,$six,$seven,$nine,$ten], 'shuffle10av'],
[ $next10->(), [$eight,$six,$seven,$ten,$nine], 'shuffle10aw'],
[ $next10->(), [$eight,$six,$nine,$seven,$ten], 'shuffle10ax'],
[ $next10->(), [$eight,$six,$nine,$ten,$seven], 'shuffle10ay'],
[ $next10->(), [$eight,$six,$ten,$seven,$nine], 'shuffle10az'],
[ $next10->(), [$eight,$six,$ten,$nine,$seven], 'shuffle10ba'],
[ $next10->(), [$eight,$seven,$six,$nine,$ten], 'shuffle10bb'],
[ $next10->(), [$eight,$seven,$six,$ten,$nine], 'shuffle10bc'],
[ $next10->(), [$eight,$seven,$nine,$six,$ten], 'shuffle10bd'],
[ $next10->(), [$eight,$seven,$nine,$ten,$six], 'shuffle10be'],
[ $next10->(), [$eight,$seven,$ten,$six,$nine], 'shuffle10bf'],
[ $next10->(), [$eight,$seven,$ten,$nine,$six], 'shuffle10bg'],
[ $next10->(), [$eight,$nine,$six,$seven,$ten], 'shuffle10bh'],
[ $next10->(), [$eight,$nine,$six,$ten,$seven], 'shuffle10bi'],
[ $next10->(), [$eight,$nine,$seven,$six,$ten], 'shuffle10bj'],
[ $next10->(), [$eight,$nine,$seven,$ten,$six], 'shuffle10bk'],
[ $next10->(), [$eight,$nine,$ten,$six,$seven], 'shuffle10bl'],
[ $next10->(), [$eight,$nine,$ten,$seven,$six], 'shuffle10bm'],
[ $next10->(), [$eight,$ten,$six,$seven,$nine], 'shuffle10bn'],
[ $next10->(), [$eight,$ten,$six,$nine,$seven], 'shuffle10bo'],
[ $next10->(), [$eight,$ten,$seven,$six,$nine], 'shuffle10bp'],
[ $next10->(), [$eight,$ten,$seven,$nine,$six], 'shuffle10bq'],
[ $next10->(), [$eight,$ten,$nine,$six,$seven], 'shuffle10br'],
[ $next10->(), [$eight,$ten,$nine,$seven,$six], 'shuffle10bs'],
[ $next10->(), [$nine,$six,$seven,$eight,$ten], 'shuffle10bt'],
[ $next10->(), [$nine,$six,$seven,$ten,$eight], 'shuffle10bu'],
[ $next10->(), [$nine,$six,$eight,$seven,$ten], 'shuffle10bv'],
[ $next10->(), [$nine,$six,$eight,$ten,$seven], 'shuffle10bw'],
[ $next10->(), [$nine,$six,$ten,$seven,$eight], 'shuffle10bx'],
[ $next10->(), [$nine,$six,$ten,$eight,$seven], 'shuffle10by'],
[ $next10->(), [$nine,$seven,$six,$eight,$ten], 'shuffle10bz'],
[ $next10->(), [$nine,$seven,$six,$ten,$eight], 'shuffle10ca'],
[ $next10->(), [$nine,$seven,$eight,$six,$ten], 'shuffle10cb'],
[ $next10->(), [$nine,$seven,$eight,$ten,$six], 'shuffle10cc'],
[ $next10->(), [$nine,$seven,$ten,$six,$eight], 'shuffle10cd'],
[ $next10->(), [$nine,$seven,$ten,$eight,$six], 'shuffle10ce'],
[ $next10->(), [$nine,$eight,$six,$seven,$ten], 'shuffle10cf'],
[ $next10->(), [$nine,$eight,$six,$ten,$seven], 'shuffle10cg'],
[ $next10->(), [$nine,$eight,$seven,$six,$ten], 'shuffle10ch'],
[ $next10->(), [$nine,$eight,$seven,$ten,$six], 'shuffle10ci'],
[ $next10->(), [$nine,$eight,$ten,$six,$seven], 'shuffle10cj'],
[ $next10->(), [$nine,$eight,$ten,$seven,$six], 'shuffle10ck'],
[ $next10->(), [$nine,$ten,$six,$seven,$eight], 'shuffle10cl'],
[ $next10->(), [$nine,$ten,$six,$eight,$seven], 'shuffle10cm'],
[ $next10->(), [$nine,$ten,$seven,$six,$eight], 'shuffle10cn'],
[ $next10->(), [$nine,$ten,$seven,$eight,$six], 'shuffle10co'],
[ $next10->(), [$nine,$ten,$eight,$six,$seven], 'shuffle10cp'],
[ $next10->(), [$nine,$ten,$eight,$seven,$six], 'shuffle10cq'],
[ $next10->(), [$ten,$six,$seven,$eight,$nine], 'shuffle10cr'],
[ $next10->(), [$ten,$six,$seven,$nine,$eight], 'shuffle10cs'],
[ $next10->(), [$ten,$six,$eight,$seven,$nine], 'shuffle10ct'],
[ $next10->(), [$ten,$six,$eight,$nine,$seven], 'shuffle10cu'],
[ $next10->(), [$ten,$six,$nine,$seven,$eight], 'shuffle10cv'],
[ $next10->(), [$ten,$six,$nine,$eight,$seven], 'shuffle10cw'],
[ $next10->(), [$ten,$seven,$six,$eight,$nine], 'shuffle10cx'],
[ $next10->(), [$ten,$seven,$six,$nine,$eight], 'shuffle10cy'],
[ $next10->(), [$ten,$seven,$eight,$six,$nine], 'shuffle10cz'],
[ $next10->(), [$ten,$seven,$eight,$nine,$six], 'shuffle10da'],
[ $next10->(), [$ten,$seven,$nine,$six,$eight], 'shuffle10db'],
[ $next10->(), [$ten,$seven,$nine,$eight,$six], 'shuffle10dc'],
[ $next10->(), [$ten,$eight,$six,$seven,$nine], 'shuffle10dd'],
[ $next10->(), [$ten,$eight,$six,$nine,$seven], 'shuffle10de'],
[ $next10->(), [$ten,$eight,$seven,$six,$nine], 'shuffle10df'],
[ $next10->(), [$ten,$eight,$seven,$nine,$six], 'shuffle10dg'],
[ $next10->(), [$ten,$eight,$nine,$six,$seven], 'shuffle10dh'],
[ $next10->(), [$ten,$eight,$nine,$seven,$six], 'shuffle10di'],
[ $next10->(), [$ten,$nine,$six,$seven,$eight], 'shuffle10dj'],
[ $next10->(), [$ten,$nine,$six,$eight,$seven], 'shuffle10dk'],
[ $next10->(), [$ten,$nine,$seven,$six,$eight], 'shuffle10dl'],
[ $next10->(), [$ten,$nine,$seven,$eight,$six], 'shuffle10dm'],
[ $next10->(), [$ten,$nine,$eight,$six,$seven], 'shuffle10dn'],
[ $next10->(), [$ten,$nine,$eight,$seven,$six], 'shuffle10do'],
[ $next10->(), [], 'shuffle10 last']

);

plan tests => $#tests + 1;

is_deeply( $_->[0], $_->[ 1, ], $_->[ 2] ) for @tests;
