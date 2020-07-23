#!/usr/bin/perl -w
use strict;
use warnings;
use diagnostics;

use Test::More tests => 45;
use Test::Exception;
### tests
BEGIN { use_ok("File::FormatIdentification::Regex"); }
is( and_combine( '^', '$' ), '^$', 'and_combine(\'^\', \'$\')' );

# example from https://stackoverflow.com/questions/869809/combine-regexp#870506
is( and_combine( '^abc', 'xyz$' ),
    '(?=^abc)(?=.*xyz$)', 'and_combine(\'^abc\', \'xyz$\')' );

# unsure if this will be correct:
#   is(and_combine('abc', '.b.'), 'abc', "and_combine('abc', '.b.')");
# using this instead:
is( and_combine( 'abc', '.b.' ), '(?=abc)(?=.b.)',
    "and_combine('abc', '.b.')" );

# usure if we should detect this:
#   throws_ok( sub{and_combine('abc', 'xyz')}, qr(not combineable), "and_combine('abc', 'xyz') does not work");
# better to use this:
is( and_combine( 'foo', 'bar' ), "(?=foo)(?=bar)",
    "and_combine('foo', 'bar')" );
is(
    and_combine( 'foo', 'bar', 'baz' ),
    "(?=foo)(?=bar)(?=baz)",
    "and_combine('foo', 'bar', 'baz')"
);

# because Regex::Assemble changes order, following does not work:
#   (or_combine('foo', 'bar'), '(?:foo|bar)', "or_combine('foo', 'bar')");
# using this instead:
is( or_combine( 'foo', 'bar' ), '(?:bar|foo)', "or_combine('foo', 'bar')" );
is( or_combine( 'foo', 'bar', 'baz' ),
    '(?:ba[rz]|foo)', "or_combine('foo', 'bar', 'baz')" );
###
use File::FormatIdentification::Regex
  qw( hex_replace_from_bracket hex_replace_to_bracket );
is(
    hex_replace_to_bracket('\x00\x00\x00\x00\x00'),
    '\x{00}\x{00}\x{00}\x{00}\x{00}',
    'hex_replace_to_bracket(\'\x00\x00\x00\x00\x00\')'
);
is( hex_replace_from_bracket('\x{00}\x{00}\x{00}\x{00}\x{00}'),
    '\x00\x00\x00\x00\x00',
    'hex_replace_from_bracket(\'\x{00}\x{00}\x{00}\x{00}\x{00}\')' );
###
is( peep_hole_optimizer("foo"),    "foo",    "peep_hole_optimizer('foo')" );
is( peep_hole_optimizer("^foo"),   "^foo",   "peep_hole_optimizer('^foo')" );
is( peep_hole_optimizer("^(foo)"), "^(foo)", "peep_hole_optimizer('^(foo)')" );
is( peep_hole_optimizer("^((foo))"),
    "^(foo)", "peep_hole_optimizer('^((foo))')" );
is( peep_hole_optimizer("^((foo)|(bar))"),
    "^((foo)|(bar))", "peep_hole_optimizer('^((foo)|(bar))')" );
is( peep_hole_optimizer("^(((foo)|(bar)))"),
    "^((foo)|(bar))", "peep_hole_optimizer('^(((foo)|(bar)))')" );
is( peep_hole_optimizer("^(((foo))|(bar))"),
    "^((foo)|(bar))", "peep_hole_optimizer('^(((foo))|(bar))')" );
is( peep_hole_optimizer("^((foo)|((bar)))"),
    "^((foo)|(bar))", "peep_hole_optimizer('^((foo)|((bar)))')" );
is( peep_hole_optimizer("(bar|baz)"),
    "(ba(r|z))", "peep_hole_optimizer('(bar|baz)')" );
is( peep_hole_optimizer('(\x{42}|\x{43})'),
    '(\x{42}|\x{43})', 'peep_hole_optimizer(\'(\x{42}|\x{43})\')' );
is( peep_hole_optimizer('(\x{34}|\x{44})'),
    '(\x{34}|\x{44})', 'peep_hole_optimizer(\'(\x{34}|\x{44})\')' );
is( peep_hole_optimizer('(\x{344}|\x{444})'),
    '(\x{344}|\x{444})', 'peep_hole_optimizer(\'(\x{344}|\x{444})\')' );
is( peep_hole_optimizer("((bar)|(baz))"),
    "(ba(r|z))", "peep_hole_optimizer('((bar)|(baz))')" );
is( peep_hole_optimizer("(barf|bazaar)"),
    "(ba(rf|zaar))", "peep_hole_optimizer('(barf|bazaar)')" );
is( peep_hole_optimizer("(raf|saf)"),
    "((r|s)af)", "peep_hole_optimizer('(raf|saf)')" );
is( peep_hole_optimizer("(braf|asaf)"),
    "((br|as)af)", "peep_hole_optimizer('(braf|asaf)')" );
is( peep_hole_optimizer("(rag|saf)"),
    "(rag|saf)", "peep_hole_optimizer('(rag|saf)')" );
is( peep_hole_optimizer("barbara"),
    "(bar){2}a", "peep_hole_optimizer('barbara')" );
is( peep_hole_optimizer("toooor"), "to{4}r", "peep_hole_optimizer('toooor')" );
is( peep_hole_optimizer("toooooooooooor"),
    "to{12}r", "peep_hole_optimizer('toooooooooor')" );
is( peep_hole_optimizer('\x{00}\x{00}\x{00}\x{00}\x{00}'),
    '\x{00}{5}', 'peep_hole_optimizer(\'\x{00}\x{00}\x{00}\x{00}\x{00}\')' );
is(
    peep_hole_optimizer(
        '\A(\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{C2})'),
    '\A(\x{00}{12}\x{C2})',
'peep_hole_optimizer(\'\A(\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{00}\x{C2})\')'
);
is( peep_hole_optimizer('\x{00}00000007006\x{20}'),
    '\x{00}0{7}7006\x{20}', 'peep_hole_optimizer(\'\x{00}00000007006\x{20}\')' );
is( peep_hole_optimizer("rhabarbarbarabarbara"),
    "rha(bar){3}a(bar){2}a", "peep_hole_optimizer('rhabarbarbarabarbara')" );
is( peep_hole_optimizer("a{100000}"),
    "a{100000}", "peep_hole_optimizer('a{100000}')" );
###
is( calc_quality('^'),         0,      "calc_quality('^')" );
is( calc_quality('foo'),       1.098,  "calc_quality('foo')" );
is( calc_quality('fo{2}'),     1.098,  "calc_quality('fo{2}'" );
is( calc_quality('fo{2,}'),    1.098,  "calc_quality('fo{2,}'" );
is( calc_quality('^foo'),      1.098,  "calc_quality('^foo')" );
is( calc_quality('[fo]o'),     -0.405, "calc_quality('[fo]o')" );
is( calc_quality('[^fo]o'),    -4.848, "calc_quality('[^fo]o')" );
is( calc_quality('.o'),        -4.855, "calc_quality('.o')" );
is( calc_quality('foobarbaz'), 2.197,  "calc_quality('foobarbaz')" );
is( calc_quality('.........'), -5.545, "calc_quality('.........')" );
