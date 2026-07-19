use strict;
use warnings;
use Test::More 0.98;

# Fixed adversarial parser inputs. Complements the
# randomized util/parser-fuzz.pl with named regression cases: each must
# either parse or raise a normal GraphQL::Houtou::Error, never crash and
# never hang. Parses run in a forked child so a regression that
# reintroduces a crash surfaces as a failed assertion rather than taking
# the test process down with it.

use GraphQL::Houtou qw(parse);

# 'parsed' | 'error' | 'CRASH'
sub parse_outcome {
  my ($input) = @_;
  my $pid = fork();
  die "fork failed: $!" if !defined $pid;
  if ($pid == 0) {
    my $ok = eval { parse($input); 1 };
    exit($ok ? 0 : 1);
  }
  waitpid $pid, 0;
  return 'CRASH' if $? & 127;
  return $? >> 8 == 0 ? 'parsed' : 'error';
}

my %CASES = (
  'invalid unicode escape' => '{ f(a: "\uZZZZ") }',
  'lone high surrogate' => '{ f(a: "\uD83D") }',
  'lone low surrogate' => '{ f(a: "\uDE00") }',
  'unterminated string' => '{ f(a: "no closing quote',
  'unterminated block string' => '{ f(a: """no closing',
  'NUL byte in the middle' => "{ a\x00b }",
  'bare NUL' => "\x00",
  'raw control bytes' => "{ \x01\x02\x03 }",
  'invalid UTF-8 continuation' => "{ f(a: \"\xC3\x28\") }",
  'overlong UTF-8' => "{ \xC0\xAF }",
  'huge integer literal' => '{ f(a: ' . ('9' x 5000) . ') }',
  'huge float exponent' => '{ f(a: 1.0e' . ('9' x 5000) . ') }',
  'many leading minus' => '{ f(a: ' . ('-' x 1000) . '1) }',
  'unbalanced closers' => '{ a } } } }',
  'only openers (bounded)' => '{' x 1000,
  'deep brackets in value' => '{ f(a: ' . ('[' x 1000) . ') }',
  'empty document' => '',
  'whitespace only' => "   \n\t  ",
  'just a comment' => "# nothing here\n",
  'BOM then query' => "\x{feff}{ a }",
  'name with all digits after' => '{ ' . ('a' x 100000) . ' }',
  'giant comment' => '# ' . ('x' x 200000) . "\n{ a }",
  'nested block string quotes' => '{ f(a: """he said """"") }',
  'spread without name' => '{ ... }',
  'directive without name' => '{ a @ }',
  'variable without name' => 'query($) { a }',
);

for my $label (sort keys %CASES) {
  my $outcome = parse_outcome($CASES{$label});
  isnt $outcome, 'CRASH', "$label does not crash the parser"
    or diag "input crashed the parser";
}

# The all-'a' name and giant comment should actually parse (they are valid,
# just large); confirm the parser handles them rather than only not
# crashing.
subtest 'large-but-valid inputs parse' => sub {
  is parse_outcome('{ ' . ('a' x 100000) . ' }'), 'parsed', 'a 100k-char field name';
  is parse_outcome('# ' . ('x' x 200000) . "\n{ a }"), 'parsed', 'a 200k-char comment';
};

done_testing;
