#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Digest::SHA ();
use Game::Gin;
use Game::Gin::Deadwood qw(best);
use Game::Gin::Terminal;

plan tests => 6;

my @chars;
open my $in,  '<', \(my $typed = '') or die $!;
open my $out, '>', \my $shown or die $!;

my $ui = Game::Gin::Terminal->new(
    in          => $in,
    out         => $out,
    ascii       => 1,
    colour      => 0,
    interactive => 0,
    picking     => 1,
    keysource   => sub { shift @chars },
);

$ui->game(Game::Gin->build(seed => Digest::SHA::sha256('melds'), dealer => 'p1'));
my $seat = $ui->game->turn;
$ui->game->apply($seat, { kind => 'take' });

my $melding = best($ui->game->deal->hand_of($seat)->cards);
my @fan = map { @{ $_->{cards} } } @{ $ui->hand_groups($melding) };

my $picker = $ui->discard_picker($seat);
my @items = @{ $picker->items };

is_deeply([ map { $_->{value}{card} } @items ], \@fan,
    'the picker holds every card of the fan, in the order the fan draws them');

my @skipped = grep { $items[$_]{skip} } 0 .. $#items;
is(scalar @skipped, 1, 'one card is drawn and cannot be thrown: the one just taken');

my @open = grep { !$items[$_]{skip} } 0 .. $#items;
my ($loose) = grep { $items[$_]{value}{loose} } @open;
is($picker->at, $loose, 'the cursor rests on the first loose card');

my @visited = ($picker->at);
for (1 .. $#open) {
    $picker->step('right');
    push @visited, $picker->at;
}
my ($from) = grep { $open[$_] == $loose } 0 .. $#open;
is_deeply(\@visited, [ map { $open[ ($from + $_) % @open ] } 0 .. $#open ],
    'right visits every card that can be thrown, left to right, and never the other');

$picker->step('right');
is($picker->at, $loose, 'and comes round to where it started');

my @keyed;
for my $key (qw/ up down left tab /) {
    my $before = $picker->at;
    $picker->step($key);
    my ($was) = grep { $open[$_] == $before } 0 .. $#open;
    my ($now) = grep { $open[$_] == $picker->at } 0 .. $#open;
    push @keyed, ($now - $was) % @open == 1 ? 'right' : 'left';
}
is_deeply(\@keyed, [qw/ right left left right /],
    'up goes right and down goes left, as right and left do');
