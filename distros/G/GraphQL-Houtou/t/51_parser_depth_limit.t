use strict;
use warnings;
use Test::More 0.98;

# Parser nesting-depth cap. The recursive-descent
# parser used to overflow the C stack on deeply nested input (~35k levels
# segfaulted an 8MB stack) before any validation ran, so a single
# unauthenticated request could kill the worker. The cap turns runaway
# nesting into a clean parse error. Each deep case runs in a forked child
# so that, if the guard ever regresses, the SIGSEGV is observed here
# instead of taking the whole test process down.

use GraphQL::Houtou qw(build_native_runtime parse);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

# Run parse($query) in a child; return 'parsed' | 'too-deep' | 'other-error'
# | 'CRASH'. Isolating the parse means a regression surfaces as a failed
# assertion, never a crashed test run.
sub parse_outcome {
  my ($query) = @_;
  my $pid = fork();
  die "fork failed: $!" if !defined $pid;
  if ($pid == 0) {
    my $ok = eval { parse($query); 1 };
    my $code = $ok ? 0 : (($@ =~ /too deeply nested/) ? 3 : 2);
    exit $code;
  }
  waitpid $pid, 0;
  my $status = $?;
  return 'CRASH' if $status & 127;
  my $code = $status >> 8;
  return $code == 0 ? 'parsed' : $code == 3 ? 'too-deep' : 'other-error';
}

sub nested_selection { '{' . ('a{' x $_[0]) . 'b' . ('}' x ($_[0] + 1)) }
sub nested_value { '{ f(a: ' . ('[' x $_[0]) . '1' . (']' x $_[0]) . ') }' }

subtest 'deeply nested selection sets are a clean error, not a crash' => sub {
  is parse_outcome(nested_selection(511)), 'parsed', 'just under the cap parses';
  is parse_outcome(nested_selection(513)), 'too-deep', 'over the cap is a clean error';
  is parse_outcome(nested_selection(35_000)), 'too-deep',
    'the former segfault depth is a clean error';
};

subtest 'deeply nested input values are a clean error, not a crash' => sub {
  is parse_outcome(nested_value(511)), 'parsed', 'just under the cap parses';
  is parse_outcome(nested_value(1000)), 'too-deep', 'over the cap is a clean error';
  is parse_outcome(nested_value(100_000)), 'too-deep',
    'the former segfault depth is a clean error';
};

subtest 'the cap tracks nesting, not width (siblings are independent)' => sub {
  my $wide_fields = '{ ' . join(' ', map { "f$_" } 1 .. 5000) . ' }';
  is parse_outcome($wide_fields), 'parsed', '5000 sibling fields parse';

  my $wide_list = '{ f(a: [' . join(',', (1) x 5000) . ']) }';
  is parse_outcome($wide_list), 'parsed', 'a 5000-element list value parses';

  # Two sibling subtrees each nested 400 deep: the depth counter must
  # unwind between them, so neither pushes the other over the cap.
  my $deep = ('a{' x 400) . 'b' . ('}' x 400);
  is parse_outcome("{ x$deep y$deep }"), 'parsed',
    'adjacent deep subtrees are counted independently';
};

subtest 'a huge but flat document is capped by the token limit' => sub {
  sub token_outcome {
    my ($query) = @_;
    my $pid = fork();
    die "fork failed: $!" if !defined $pid;
    if ($pid == 0) {
      my $ok = eval { parse($query); 1 };
      exit($ok ? 0 : (($@ =~ /too many tokens/) ? 3 : 2));
    }
    waitpid $pid, 0;
    return 'CRASH' if $? & 127;
    my $code = $? >> 8;
    return $code == 0 ? 'parsed' : $code == 3 ? 'too-many' : 'other-error';
  }

  # Use the shortest legal field name so the smoke test stays memory-light
  # while still exercising a very wide document.
  my $under = '{ ' . join(' ', ('f') x 600_000) . ' }';
  is token_outcome($under), 'parsed', '600k sibling fields parse';

  # ~1.1M tokens is a multi-MB adversarial document, not a real request.
  my $over = '{ ' . join(' ', ('f') x 1_100_000) . ' }';
  is token_outcome($over), 'too-many', 'a 1.1M-token document is a clean error';
};

subtest 'the depth error reaches execute_document as a request error' => sub {
  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => { a => { type => $String, resolve => sub { 'x' } } },
    ),
  );
  my $runtime = build_native_runtime($schema);
  my $pid = fork();
  die "fork failed: $!" if !defined $pid;
  if ($pid == 0) {
    my $result = eval { $runtime->execute_document(nested_selection(35_000)) };
    my $ok = $result
      && !exists $result->{data}
      && $result->{errors}
      && $result->{errors}[0]{message} =~ /too deeply nested/;
    exit($ok ? 0 : 1);
  }
  waitpid $pid, 0;
  ok !($? & 127), 'execute_document does not crash on the former segfault input';
  is $? >> 8, 0, 'it returns an errors-only envelope naming the depth limit';
};

done_testing;
