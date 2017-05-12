#!perl -T

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('Macro::Micro'); }

my $text = <<END_TEXT;
  I enjoy drinking <SILENCE>[FAVORITE_BEVERAGE].
  I enjoy drinking <SILENCE>[FAVORITE_BEVERAGE].
  I enjoy drinking <SILENCE>[FAVORITE_BEVERAGE].
  I enjoy drinking <SILENCE>[FAVORITE_BEVERAGE].
  I enjoy drinking <SILENCE>[FAVORITE_BEVERAGE].
  I enjoy drinking <SILENCE>[FAVORITE_BEVERAGE].
  My turn-ons include [TURN_ONS] but not [TURN_OFFS].

  My head, which is flat, is [AREA_OF_FLATHEAD] square inches in area.

  <SECRET_YOUR_FACE>
  My turn-ons include [TURN_ONS] but not [TURN_OFFS].

  My head, which is flat, is [AREA_OF_FLATHEAD] square inches in area.

  <SECRET_YOUR_FACE>
  My turn-ons include [TURN_ONS] but not [TURN_OFFS].

  My head, which is flat, is [AREA_OF_FLATHEAD] square inches in area.

  <SECRET_YOUR_FACE>
  My turn-ons include [TURN_ONS] but not [TURN_OFFS].

  My head, which is flat, is [AREA_OF_FLATHEAD] square inches in area.

  <SECRET_YOUR_FACE>
  My turn-ons include [TURN_ONS] but not [TURN_OFFS].

  My head, which is flat, is [AREA_OF_FLATHEAD] square inches in area.

  <SECRET_YOUR_FACE>
  My turn-ons include [TURN_ONS] but not [TURN_OFFS].

  My head, which is flat, is [AREA_OF_FLATHEAD] square inches in area.

  <SECRET_YOUR_FACE>
  I enjoy drinking <SILENCE>[FAVORITE_BEVERAGE].
  My turn-ons include [TURN_ONS] but not [TURN_OFFS].

  My head, which is flat, is [AREA_OF_FLATHEAD] square inches in area.

  <SECRET_YOUR_FACE>
END_TEXT
chomp $text;

my $expander = Macro::Micro->new;

my @macros = (
  FAVORITE_BEVERAGE => sub { "hot tea" },
  TURN_ONS          => "50,000 volts",
  TURN_OFFS         => "electromagnetic pulses",
  # qr/SECRET_\w+/    => sub { "(secret macro! $_[0]!)" },
  SECRET_YOUR_FACE  => "(secret macro! SECRET_YOUR_FACE!)",
  AREA_OF_FLATHEAD  => sub { ($_[2]->{edge}||0) ** 2 },
  SILENCE           => '',
);

for (1 .. 10000) {
  $expander->clear_macros;
  my $filled_in = $expander->register_macros(@macros)->expand_macros(
    $text,
    { edge=>2 }
  );

  my $expected = <<END_TEXT;
  I enjoy drinking hot tea.
  I enjoy drinking hot tea.
  I enjoy drinking hot tea.
  I enjoy drinking hot tea.
  I enjoy drinking hot tea.
  I enjoy drinking hot tea.
  My turn-ons include 50,000 volts but not electromagnetic pulses.

  My head, which is flat, is 4 square inches in area.

  (secret macro! SECRET_YOUR_FACE!)
  My turn-ons include 50,000 volts but not electromagnetic pulses.

  My head, which is flat, is 4 square inches in area.

  (secret macro! SECRET_YOUR_FACE!)
  My turn-ons include 50,000 volts but not electromagnetic pulses.

  My head, which is flat, is 4 square inches in area.

  (secret macro! SECRET_YOUR_FACE!)
  My turn-ons include 50,000 volts but not electromagnetic pulses.

  My head, which is flat, is 4 square inches in area.

  (secret macro! SECRET_YOUR_FACE!)
  My turn-ons include 50,000 volts but not electromagnetic pulses.

  My head, which is flat, is 4 square inches in area.

  (secret macro! SECRET_YOUR_FACE!)
  My turn-ons include 50,000 volts but not electromagnetic pulses.

  My head, which is flat, is 4 square inches in area.

  (secret macro! SECRET_YOUR_FACE!)
  I enjoy drinking hot tea.
  My turn-ons include 50,000 volts but not electromagnetic pulses.

  My head, which is flat, is 4 square inches in area.

  (secret macro! SECRET_YOUR_FACE!)
END_TEXT
  chomp $expected; # XXX why do I need this?

  is($filled_in, $expected, "we filled in a studied string");
}
