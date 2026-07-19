#!/usr/bin/env perl
use strict;
use warnings;

# Parser fuzz smoke. The recursive-descent parser is
# C and faces untrusted input directly, so a crash is a downed worker. This
# mutates known-good documents (the vendored fixtures) with byte-level and
# structural corruptions and asserts the parser never crashes: every input
# either parses or raises a normal error. Run it under ASan to turn latent
# memory bugs into hard failures:
#
#   perl Build.PL --config optimize="-O2 -g -fsanitize=address -fno-omit-frame-pointer" \
#                 --config lddlflags="-shared -fsanitize=address"
#   ./Build
#   LD_PRELOAD=$(gcc -print-file-name=libasan.so) \
#     perl -Iblib/lib -Iblib/arch util/parser-fuzz.pl --iterations 50000
#
# A crash here is a SIGSEGV/SIGABRT taking the whole process down; the exit
# status reflects that. Clean parse errors are the expected outcome and are
# not failures.

use Getopt::Long qw(GetOptions);
use GraphQL::Houtou qw(parse);

my $iterations = 20000;
my $seed = defined $ENV{FUZZ_SEED} ? $ENV{FUZZ_SEED} : time ^ $$;
GetOptions(
  'iterations=i' => \$iterations,
  'seed=i'       => \$seed,
) or die "usage: $0 [--iterations N] [--seed N]\n";

srand($seed);
print "parser-fuzz: iterations=$iterations seed=$seed\n";

# Seed corpus: the vendored fixtures plus a spread of small documents that
# exercise every token kind and construct.
my @corpus;
for my $path (glob 't/*.graphql') {
  open my $fh, '<', $path or next;
  local $/;
  push @corpus, scalar <$fh>;
}
push @corpus,
  '{ a b c }',
  'query Q($v: Int = 3) { f(a: $v, b: [1, 2, {x: "y"}]) @dir { g } }',
  '{ ... on T { a } ...Frag } fragment Frag on T { b }',
  'mutation M { do(input: {a: true, b: null, c: 1.5e10}) }',
  'query { u(s: "line1\nline2 é 😀 \t\\") }',
  "\x{feff}{ withBom }",
  '"""block string""" { x }';
@corpus = grep { defined && length } @corpus;

# Structural / byte-level mutators. Each takes a string and returns a
# mutated copy.
my @mutators = (
  # Truncate at a random point.
  sub { substr($_[0], 0, int(rand(length($_[0]) + 1))) },
  # Flip a random byte.
  sub {
    my $s = $_[0];
    return $s if !length $s;
    my $i = int(rand(length $s));
    substr($s, $i, 1) = chr(int(rand(256)));
    $s;
  },
  # Insert a run of a random byte (widen tokens / break structure).
  sub {
    my $s = $_[0];
    my $i = int(rand(length($s) + 1));
    substr($s, $i, 0) = chr(int(rand(256))) x (1 + int(rand(64)));
    $s;
  },
  # Duplicate a random slice (unbalance brackets/braces).
  sub {
    my $s = $_[0];
    return $s if length($s) < 2;
    my $i = int(rand(length $s));
    my $len = 1 + int(rand(length($s) - $i));
    substr($s, $i, 0) = substr($s, $i, $len);
    $s;
  },
  # Repeat an opener to probe nesting (bounded well under a crash, but the
  # depth cap should still make it a clean error).
  sub {
    my $s = $_[0];
    my $open = ('{', '[', '(')[int(rand(3))];
    ($open x (1 + int(rand(2000)))) . $s;
  },
  # Delete a random slice.
  sub {
    my $s = $_[0];
    return $s if length($s) < 2;
    my $i = int(rand(length $s));
    my $len = 1 + int(rand(length($s) - $i));
    substr($s, $i, $len) = '';
    $s;
  },
);

my ($parsed, $errored) = (0, 0);
for my $n (1 .. $iterations) {
  my $input = $corpus[int(rand(@corpus))];
  # Apply 1-3 mutations.
  for (1 .. 1 + int(rand(3))) {
    $input = $mutators[int(rand(@mutators))]->($input);
  }
  my $ok = eval { parse($input); 1 };
  if ($ok) { $parsed++ } else { $errored++ }
  # A crash (SIGSEGV/SIGABRT) never returns here; it kills the process and
  # the non-zero exit is the signal. eval only catches Perl-level die.
}

print "parser-fuzz: parsed=$parsed errored=$errored (no crash)\n";
print "parser-fuzz PASSED\n";
