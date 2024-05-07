# perl

use v5.26;

use Test::More tests => 36;
use JSON::Relaxed;

my $p = JSON::Relaxed::Parser->new;

is( $p->parse( q{ "foo" } ),        "foo",     "simple string" );
is( $p->parse( q{ "fo\uo" } ),      "fouo",    "\\u" );
is( $p->parse( q{ "fo\u0o" } ),     "fou0o",   "\\u0" );
is( $p->parse( q{ "fo\u00o" } ),    "fou00o",  "\\u00" );
is( $p->parse( q{ "fo\u002o" } ),   "fou002o", "\\u002" );
is( $p->parse( q{ "fo\u002fo" } ),  "fo/o",    "\\u002f" );
is( $p->parse( q{  fo\u002fo  } ),  "fo/o",    "\\u002f unquoted" );
is( $p->parse( q{ "fo\u002fao" } ), "fo/ao",   "\\u002fa" );

is( $p->parse( q{ "fo\uoooooo" } ), "fouoooooo",    "\\u..." );
is( $p->parse( q{ "fo\u0ooooo" } ), "fou0ooooo",   "\\u0..." );
is( $p->parse( q{ "fo\u00oooo" } ), "fou00oooo",  "\\u00..." );
is( $p->parse( q{ "fo\u002ooo" } ), "fou002ooo", "\\u002..." );
is( $p->parse( q{ "fo\u002foo" } ), "fo/oo",    "\\u002f..." );
is( $p->parse( q{ "fo\u002fao" } ), "fo/ao",   "\\u002fa..." );

# UTF-16 surrogates.
is( $p->parse( q{ "fo\uD834\uDD0Eao" } ), "fo\x{1d10e}ao",   "\\uD834\\uDD0E" );
is( $p->parse( q{  fo\uD834\uDD0Eao  } ), "fo\x{1d10e}ao",   "\\uD834\\uDD0E unquoted" );

# Non-BMP UTF-8.
is( $p->parse( ' "\u{2}" ' ),        "\x{2}",     "\\u{2}" );
is( $p->parse( ' "\u{02}" ' ),       "\x{2}",     "\\u{02}" );
is( $p->parse( ' "\u{002}" ' ),      "\x{2}",     "\\u{002}" );
is( $p->parse( ' "\u{0002}" ' ),     "\x{2}",     "\\u{0002}" );
is( $p->parse( ' "\u{00002}" ' ),    "\x{2}",     "\\u{00002}" );
is( $p->parse( ' "\u{1d10e}" ' ),    "\x{1d10e}", "\\u{1d10e}" );

# Boundaries.
is( $p->parse( q{\u002} ),         "u002",      "\\u002" );
diag($p->err_msg) if $p->is_error;
is( $p->parse( q{"\u002"} ),         "u002",      "\\u002" );
diag($p->err_msg) if $p->is_error;
is( $p->parse( q{"\u002f"} ),       "/",         "\\u002f" );
is( $p->parse( q{"\uD834"} ),       "\x{D834}",  "\\uD834" );
is( $p->parse( q{"\uD834\uDD0E"} ), "\x{1d10e}", "\\uD834\\uDD0E" );
is( $p->parse( q{\uD834\uDD0E}),    "\x{1d10e}", "\\uD834\\uDD0E unquoted" );
is( $p->parse( q{"\u002"} ),        "u002",      "\\u002" );
is( $p->parse( q{"\u002f"} ),       "/",         "\\u002f" );
is( $p->parse( q{"\uD834"} ),       "\x{D834}",  "\\uD834" );
is( $p->parse( q{"\uD834\uDD0E"} ), "\x{1d10e}", "\\uD834\\uDD0E" );
is( $p->parse( q{\uD834\uDD0E} ),   "\x{1d10e}", "\\uD834\\uDD0E unquoted" );

# Non-characters.
is( $p->parse( ' "\u{00002g}"' ),  "u{00002g}", "\\u{00002g}" );
is( $p->parse( ' "\u{00002g"'  ),  "u{00002g",  "\\u{00002g" );
is( $p->parse( ' "\u{00002"'   ),  "u{00002",   "\\u{00002" );
