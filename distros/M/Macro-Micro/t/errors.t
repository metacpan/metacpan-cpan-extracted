#!perl

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('Macro::Micro'); }

my $expander = Macro::Micro->new;

is(
  $expander->get_macro("HLAGH"),
  undef,
  "there is no 'HLAGH' macro",
);

$expander->register_macros(
  BAR     => "FOO",
  qr/FOO/ => "BAR",
);

eval { $expander->register_macros( \2 => "two" ); };
like($@, qr/string or a regexp/, "you can't name a macro with a weird ref");

eval { $expander->register_macros( QUUX => qr/./ ); };
like($@, qr/string or code ref/, "a macro value must be a string or coderef");

is(
  $expander->get_macro("HLAGH"),
  undef,
  "there is no 'HLAGH' macro even after registering some things",
);

eval { $expander->fast_expander->({}); };
like($@, qr/not be a ref/, "a ref isn't an OK object to fast-expand");

my $text = "[FOO] <BAR> [BAZ]";

is(
  $expander->expand_macros_in(\$text),
  "BAR FOO [BAZ]",
  "unknown macros are left in place",
);

eval { $expander->expand_macros_in("[FOO][BAR]"); };
like($@, qr/must be a scalar ref/, "can't expand plain ol' strings");

eval { $expander->expand_macros_in( \*STDIN ); };
like($@, qr/must be a scalar ref/, "can't expand non-scalar refs, yet");
