#!perl

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('Macro::Micro'); }

my $expander = Macro::Micro->new;

$expander->register_macros(
  FOO => "[BAR]",
  BAR => "[FOO]",
  BAZ => "[BAZ]",
  OOO => "[FOO][BAR]",
);

{
  my $text     = "[FOO][BAR][OOO][BAZ]";
  my $expected = "[BAR][FOO][FOO][BAR][BAZ]";

  is(
    $expander->expand_macros($text),
    $expected,
    "we get no stupid recursive expansion",
  );
}

{
  my $text     = "[FOO[BAR]][[OOO][BAZ]]";
  my $expected = "[FOO[FOO]][[FOO][BAR][BAZ]]";

  is(
    $expander->expand_macros($text),
    $expected,
    "another goofy case of nesting and dumb brackets",
  );
}
