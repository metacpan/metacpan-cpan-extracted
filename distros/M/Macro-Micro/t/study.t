#!perl -T

use strict;
use warnings;

use Test::More tests => 5;

BEGIN { use_ok('Macro::Micro'); }

my $text = <<END_TEXT;
  I enjoy drinking <SILENCE>[FAVORITE_BEVERAGE].
  My turn-ons include [TURN_ONS] but not [TURN_OFFS].

  My head, which is flat, is [AREA_OF_FLATHEAD] square inches in area.
  See me on the web at <A HREF='[URL]'>[URL]</A>.

  <SECRET_YOUR_FACE>
  SNXBLORT
END_TEXT

my $expander = Macro::Micro->new;

my $template = $expander->study($text);

{
  my @macros = (
    FAVORITE_BEVERAGE => sub { "hot tea" },
    TURN_ONS          => "50,000 volts",
    TURN_OFFS         => "electromagnetic pulses",
    qr/SECRET_\w+/    => sub { "(secret macro! $_[0]!)" },
    AREA_OF_FLATHEAD  => sub { ($_[2]->{edge}||0) ** 2 },
    SILENCE           => '',
    URL               => 'gopher://dimwit.gue/',
  );

  my $filled_in = $expander->register_macros(@macros)->expand_macros(
    $template,
    { edge=>2 }
  );

  my $expected = <<END_TEXT;
  I enjoy drinking hot tea.
  My turn-ons include 50,000 volts but not electromagnetic pulses.

  My head, which is flat, is 4 square inches in area.
  See me on the web at <A HREF='gopher://dimwit.gue/'>gopher://dimwit.gue/</A>.

  (secret macro! SECRET_YOUR_FACE!)
  SNXBLORT
END_TEXT

  is($filled_in, $expected, "we filled in a studied string");
}

my %stay_same = (
  'no macros' => 'Hello, sailor.',
  'open <'    => '<UNFINISHED macro=',
  'XML DTD'   => '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">',
);

for my $desc (keys %stay_same) {
  my $string = $stay_same{ $desc };
  my $template_no_macros = $expander->study($string);
  is($expander->expand_macros($string), $string, "$desc, same string");
}
