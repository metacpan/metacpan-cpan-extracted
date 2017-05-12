#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use Jmespath::Lexer;

$| = 1;

my ($l) = undef;

isa_ok my $lexer = Jmespath::Lexer->new, 'Jmespath::Lexer';

#is_deeply $lexer->tokenize(''), [], 'test_empty_string';

is_deeply $lexer->tokenize('foo'),
  [ { type => 'unquoted_identifier', value => 'foo', start => 0, end => 3, },
    { type => 'eof',                 value => '',    start => 3, end => 3 }, ],
  'test_field';

is_deeply $lexer->tokenize('24'),
  [ { type => 'number', value => 24, start => 0, end => 2 },
    { type => 'eof',    value => '', start => 2, end => 2 }, ],
  'test_number';

is_deeply $lexer->tokenize('-24'),
  [ { type => 'number', value => -24, start => 0, end => 3 },
    { type => 'eof',    value => '',  start => 3, end => 3 }, ],
  'test_negative_number';

is_deeply $lexer->tokenize('"foobar"'),
  [ { type => 'quoted_identifier', value => 'foobar', start => 0, end => 7 },
    { type => 'eof',               value => '',       start => 8, end => 8 }, ],
  'test_quoted_identifier';

is_deeply $lexer->tokenize('"\u2713"'),
  [ { type => 'quoted_identifier', value => "\x{2713}", start => 0, end => 7 },
    { type => 'eof',               value => '',         start => 8, end => 8 }, ],
  'test_json_escaped_value';


$l = $lexer->tokenize('foo.bar.baz');
is $l->[0]->{type}, 'unquoted_identifier';
is $l->[1]->{type}, 'dot';
is $l->[2]->{type}, 'unquoted_identifier';
is $l->[3]->{type}, 'dot';
is $l->[4]->{type}, 'unquoted_identifier';
is $l->[5]->{type}, 'eof';

is $l->[0]->{value}, 'foo';
is $l->[1]->{value}, '.';
is $l->[2]->{value}, 'bar';
is $l->[3]->{value}, '.';
is $l->[4]->{value}, 'baz';
is $l->[5]->{value}, '';

is $l->[0]->{start}, 0;
is $l->[1]->{start}, 3;
is $l->[2]->{start}, 4;
is $l->[3]->{start}, 7;
is $l->[4]->{start}, 8;
is $l->[5]->{start}, 11;

$l = $lexer->tokenize('foo.bar[*].baz | a || b');

is $l->[0]->{type}, 'unquoted_identifier';
is $l->[1]->{type}, 'dot';
is $l->[2]->{type}, 'unquoted_identifier';
is $l->[3]->{type}, 'lbracket';
is $l->[4]->{type}, 'star';
is $l->[5]->{type}, 'rbracket';
is $l->[6]->{type}, 'dot';
is $l->[7]->{type}, 'unquoted_identifier';
is $l->[8]->{type}, 'pipe';
is $l->[9]->{type}, 'unquoted_identifier';
is $l->[10]->{type}, 'or';
is $l->[11]->{type}, 'unquoted_identifier';
is $l->[12]->{type}, 'eof';


# is_deeply $lexer->tokenize('foo.bar[*].baz | a || b'),
#   [ { type => 'unquoted_identifier', value => 'foo', start => 0,  end => 2  },
#     { type => 'dot',                 value => '.'},
#     { type => 'unquoted_identifier', value => 'bar'},
#     { type => 'lbracket',            value => '['},
#     { type => 'star',                value => '*'},
#     { type => 'rbracket',            value => ']'},
#     { type => 'dot',                 value => '.'},
#     { type => 'unquoted_identifier', value => 'baz'},
#     { type => 'pipe',                value => '|'},
#     { type => 'unquoted_identifier', value => 'a'},
#     { type => 'or',                  value => '||'},
#     { type => 'unquoted_identifier', value => 'b'},
#   ], 'test_space_separated';

$l = $lexer->tokenize('`[0, 1]`');

is $l->[0]->{type}, 'literal';
is $l->[1]->{type}, 'eof';

# Test Literal String
$l = $lexer->tokenize('`foobar`');
is $l->[0]->{type}, 'literal';
is $l->[1]->{type}, 'eof';

# Test Literal Number
$l = $lexer->tokenize('`2`');
is $l->[0]->{type}, 'literal';
is $l->[1]->{type}, 'eof';

# Test literal with invalid json
try {
  $l = $lexer->tokenize('`foo"bar`');
} catch {
  isa_ok $_, 'Jmespath::LexerException', 'test_invalid_json';
};

$l = $lexer->tokenize('``');
is $l->[0]->{type},  'literal';
is $l->[1]->{type},  'eof';
is $l->[0]->{value}, '';
is $l->[1]->{value}, '';

$l = $lexer->tokenize('foo');
is $l->[0]->{type}, 'unquoted_identifier';
is $l->[1]->{type}, 'eof';
is $l->[0]->{value}, 'foo';
is $l->[1]->{value}, '';

$l = $lexer->tokenize('foo.bar');
is $l->[0]->{type}, 'unquoted_identifier';
is $l->[1]->{type}, 'dot';
is $l->[2]->{type}, 'unquoted_identifier';
is $l->[3]->{type}, 'eof';

$l = $lexer->tokenize('`{{}`');
is $l->[0]->{type}, 'literal';
is $l->[1]->{type}, 'eof';

try {
  $l = $lexer->tokenize('foo[0^]');
  fail('test_unknown_character');
} catch {
  isa_ok $_, 'Jmespath::LexerException', 'test_unknown_charater';
};

try {
  $lexer->tokenize('^foo[0]');
  fail('test_bad_first_character');
} catch {
  isa_ok $_, 'Jmespath::LexerException', 'test_bad_first_character';
};

try {
  $lexer->tokenize('foo-bar');
  fail('test_unknown_character_with_identifier');
} catch {
  isa_ok $_, 'Jmespath::LexerException',
    'test_unknown_character_with_identifier';
};

$l = $lexer->tokenize('avg(ops.*.numArgs)');
is $l->[0]->{type}, 'unquoted_identifier';
is $l->[1]->{type}, 'lparen';
is $l->[2]->{type}, 'unquoted_identifier';
is $l->[3]->{type}, 'dot';
is $l->[4]->{type}, 'star';
is $l->[5]->{type}, 'dot';
is $l->[6]->{type}, 'unquoted_identifier';
is $l->[7]->{type}, 'rparen';
is $l->[8]->{type}, 'eof';

done_testing();

