#!perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
  use_ok('Macro::Micro');
}

my $class = 'Macro::Micro';
my $expander = $class->new;

isa_ok($expander, $class);

can_ok($expander, 'register_macros');

$expander->register_macros(
  FAVORITE_BEVERAGE => sub { "hot tea" },
  TURN_ONS          => "50,000 volts",
  TURN_OFFS         => "electromagnetic pulses",
  qr/SECRET_\w+/    => sub { "(secret macro! $_[0]!)" },
  AREA_OF_FLATHEAD  => sub { ($_[2]->{edge}||0) ** 2 },
  SILENCE           => '',
);

my $text = <<END_TEXT;
  I enjoy drinking [FAVORITE_BEVERAGE].
  My turn-ons include [TURN_ONS] but not [TURN_OFFS].

  My head, which is flat, is [AREA_OF_FLATHEAD] square inches in area.

  <SECRET_YOUR_FACE>
END_TEXT

my $expected = <<END_TEXT;
  I enjoy drinking hot tea.
  My turn-ons include 50,000 volts but not electromagnetic pulses.

  My head, which is flat, is 4 square inches in area.

  (secret macro! SECRET_YOUR_FACE!)
END_TEXT

$expander->expand_macros_in(\$text, { edge => 2 });

is($text, $expected, "expansion worked as planned");

is(
  $expander->expand_macros("[TURN_ONS] \\[TURN_OFFS]"),
  "50,000 volts \\[TURN_OFFS]",
  "allow escaped macros"
);

is(
  $expander->expand_macros("[SILENCE]"),
  "",
  "a macro can expand to ''"
);
