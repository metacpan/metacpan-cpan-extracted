use strict;
use warnings;

use Test::More;

use GraphQL::Houtou qw(build_schema execute build_native_runtime);

# Regression coverage for the destruction-time SEGV first seen in PR #21 CI:
# a die() escaping from input coercion (or a resolver) longjmps past the
# execution loops' cleanup, and used to leave ExecState->field_frame pointing
# into a dead C stack frame. The crash manifested at interpreter shutdown on
# specific heap layouts (x86_64 -O2), so these tests assert the observable
# contract - the exec state stays usable after an escaped die - while CI
# exercising this file is what would catch the corruption itself.

my $schema = build_schema(q{
  type Query {
    find(by: PlainInput): String
    boom: String
    ok: String
  }
  input PlainInput { id: ID }
}, resolvers => {
  Query => {
    find => sub { 'found' },
    boom => sub { die "resolver boom\n" },
    ok => sub { 'fine' },
  },
});

subtest 'coercion die propagates and the runtime stays usable' => sub {
  # validate => 0: the request-stage validator would reject this document
  # before coercion runs; the die-through-coercion path under test is what
  # pre-validated (persisted) deployments still exercise.
  my $runtime = build_native_runtime($schema, validate => 0);

  # The coercion die still unwinds through the XS lowering path (the
  # regression under test); execute_document catches it at the request
  # boundary and reports it as a request-error envelope.
  my $bad = $runtime->execute_document('{ find(by: { nope: 1 }) }');
  like $bad->{errors}[0]{message}, qr/Unknown field/,
    'unknown input field dies through coercion';

  for my $i (1 .. 5) {
    my $repeat = $runtime->execute_document('{ find(by: { nope: 1 }) }');
    like $repeat->{errors}[0]{message}, qr/Unknown field/, "repeat $i dies cleanly";
  }

  my $result = $runtime->execute_document('{ find(by: { id: "1" }) ok }');
  ok !exists $result->{errors}, 'no errors after escaped dies';
  is_deeply $result->{data}, { find => 'found', ok => 'fine' },
    'same runtime executes normally after escaped dies';
};

subtest 'coercion die via variables keeps the runtime usable' => sub {
  my $runtime = build_native_runtime($schema);
  my $query = 'query Q($by: PlainInput) { find(by: $by) }';

  my $bad = $runtime->execute_document($query, variables => { by => { nope => 1 } });
  like $bad->{errors}[0]{message}, qr/Unknown field/, 'unknown variable input field dies';

  my $result = $runtime->execute_document($query, variables => { by => { id => '2' } });
  ok !exists $result->{errors}, 'no errors afterwards';
  is $result->{data}{find}, 'found', 'variables path recovers';
};

subtest 'many escaped dies then shutdown' => sub {
  # Amplified variant of the CI crash shape: repeated escaped dies followed
  # by interpreter shutdown while the program cache still holds the program.
  my $runtime = build_native_runtime($schema);
  for (1 .. 50) {
    eval { $runtime->execute_document('{ find(by: { nope: 1 }) }') };
  }
  ok 1, 'survived repeated escaped dies';
};

done_testing;
