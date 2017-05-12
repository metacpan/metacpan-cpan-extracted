#!perl -T

use strict;
use warnings;

use Test::More tests => 35;

my $class = 'Games::Bowling::Scorecard::AsText';

use_ok('Games::Bowling::Scorecard');
use_ok($class);

{
  my $card = Games::Bowling::Scorecard->new;

  $card->record(6,1);
  $card->record(7,2);
  $card->record(10);
  $card->record(9);

  my $expected = join "\n",
    '+-----+-----+-----+-----+-----+-----+-----+-----+-----+-------+',
    '| 6 1 | 7 2 | X   | 9   |     |     |     |     |     |       |',
    '|   7 |  16 |     |     |     |     |     |     |     |       |',
    '',
  ;

  is(
    $class->card_as_text($card),
    $expected,
    "a partial scorecard stringifies as we expected",
  );
}

{
  my $card = Games::Bowling::Scorecard->new;

  $card->record(1,1) for 1 .. 9;
  $card->record(5, 5, 0);

  my $expected = join "\n",
    '+-----+-----+-----+-----+-----+-----+-----+-----+-----+-------+',
    '| 1 1 | 1 1 | 1 1 | 1 1 | 1 1 | 1 1 | 1 1 | 1 1 | 1 1 | 5 / - |',
    '|   2 |   4 |   6 |   8 |  10 |  12 |  14 |  16 |  18 |    28 |',
    '',
  ;

  is(
    $class->card_as_text($card),
    $expected,
    "spare-then-zero-in-tenth scorecard stringifies as we expected",
  );
}

{
  my $card = Games::Bowling::Scorecard->new;

  $card->record(1,1) for 1 .. 9;
  $card->record(10); # note that we do not finish the tenth

  my $expected = join "\n",
    '+-----+-----+-----+-----+-----+-----+-----+-----+-----+-------+',
    '| 1 1 | 1 1 | 1 1 | 1 1 | 1 1 | 1 1 | 1 1 | 1 1 | 1 1 | X     |',
    '|   2 |   4 |   6 |   8 |  10 |  12 |  14 |  16 |  18 |       |',
    '',
  ;

  is(
    $class->card_as_text($card),
    $expected,
    "lousy, unfinished-in-the-tenth scorecard stringifies as we expected",
  );
}

{
  my $card = Games::Bowling::Scorecard->new;

  $card->record(6,1);  # slow start
  $card->record(7,2);  # getting better
  $card->record(10);   # strike!
  $card->record(9,1);  # picked up a spare
  $card->record(10) for 1 .. 3; # turkey!
  $card->record(0,0);  # clearly distracted by something
  $card->record(8,2);  # amazingly picked up 7-10 split
  $card->record(10, 9, 1); # pick up a bonus spare

  my $expected = join "\n",
    '+-----+-----+-----+-----+-----+-----+-----+-----+-----+-------+',
    '| 6 1 | 7 2 | X   | 9 / | X   | X   | X   | - - | 8 / | X 9 / |',
    '|   7 |  16 |  36 |  56 |  86 | 106 | 116 | 116 | 136 |   156 |',
    '',
  ;

  is(
    $class->card_as_text($card),
    $expected,
    "our scorecard stringifies as we expected",
  );
}

## little bits tested below

sub ok2 {
  my ($b1, $b2, $expected) = @_;

  my $string = sprintf '(%s, %s)',
    defined $b1 ? $b1 : 'undef',
    defined $b2 ? $b2 : 'undef';

  is(
    $class->_two_balls($b1, $b2),
    $expected,
    "two balls: $string -> '$expected'"
  );
}

ok2( (0, undef),     "-  ");
ok2( (undef, undef), "   ");

ok2( ( 0, 0), "- -");
ok2( ( 0, 1), "- 1");
ok2( ( 1, 0), "1 -");
ok2( ( 1, 1), "1 1");
ok2( ( 1, 9), "1 /");
ok2( ( 9, 1), "9 /");
ok2( (10, 0), "X  ");
ok2( (10, undef), "X  ");

sub ok3 {
  my ($b1, $b2, $b3, $expected) = @_;

  my $string = sprintf '(%s, %s, %s)',
    defined $b1 ? $b1 : 'undef',
    defined $b2 ? $b2 : 'undef',
    defined $b3 ? $b3 : 'undef';

  is(
    $class->_three_balls($b1, $b2, $b3),
    $expected,
    "three balls: $string -> '$expected'"
  );
}

ok3( (undef, undef, undef) => '     ');
ok3( (    0, undef, undef) => '-    ');
ok3( (    0,     1, undef) => '- 1  ');

ok3( (    9, undef, undef) => '9    ');
ok3( (    9,     0, undef) => '9 -  ');
ok3( (    9,     0,     0) => '9 -  ');
ok3( (    9,     1, undef) => '9 /  ');
ok3( (    9,     1,     9) => '9 / 9');
ok3( (    9,     1,    10) => '9 / X');

ok3( (   10, undef, undef) => 'X    ');
ok3( (   10,     0, undef) => 'X -  ');
ok3( (   10,     0,     0) => 'X - -');
ok3( (   10,     1, undef) => 'X 1  ');
ok3( (   10,     1,     1) => 'X 1 1');
ok3( (   10,     1,     9) => 'X 1 /');

ok3( (   10,    10, undef) => 'X X  ');
ok3( (   10,    10,     0) => 'X X -');
ok3( (   10,    10,     1) => 'X X 1');
ok3( (   10,    10,    10) => 'X X X');
