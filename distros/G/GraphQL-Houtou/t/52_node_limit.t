use strict;
use warnings;
use Test::More 0.98;

# Query node-count limit. The depth limit bounds
# nesting but not breadth: an alias-flooded query { a:f b:f c:f ... }
# stays shallow while forcing huge resolution and response. The node
# limit caps the total field selections an operation resolves, counting
# fragment spreads by expansion so { ...F ...F ... } cannot multiply
# cheaply. Wired into the request stage: over the cap is an errors-only
# envelope, like the depth limit.

use GraphQL::Houtou qw(build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);
use GraphQL::Houtou::Validation::NodeLimit qw(check_query_nodes);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => { hello => { type => $String, resolve => sub { 'x' } } },
  ),
);

sub flood { '{ ' . join(' ', map { "a$_: hello" } 1 .. $_[0]) . ' }' }

subtest 'the validator counts field selections' => sub {
  my $ast = GraphQL::Houtou::parse(flood(50));
  is_deeply [ check_query_nodes($ast, max_nodes => 100) ], [], '50 aliases under cap 100';

  my @errors = check_query_nodes(GraphQL::Houtou::parse(flood(200)), max_nodes => 100);
  is scalar @errors, 1, '200 aliases over cap 100';
  like $errors[0]{message}, qr/too many field selections/, 'names the limit';

  is_deeply [ check_query_nodes($ast, max_nodes => undef) ], [],
    'max_nodes => undef disables the check';
};

subtest 'fragment spreads count by expansion' => sub {
  # 60 spreads of a 10-field fragment = 600 selections.
  my $q = '{ ' . ('...F ' x 60) . '} fragment F on Query { '
    . join(' ', map { "b$_: hello" } 1 .. 10) . ' }';
  my @errors = check_query_nodes(GraphQL::Houtou::parse($q), max_nodes => 100);
  is scalar @errors, 1, '60 x 10 fields exceed cap 100';

  # A spread already on the current path is not re-counted (cycles are a
  # separate validation error); counting must still terminate.
  my $cyclic = '{ ...A } fragment A on Query { hello ...A }';
  my $ok = eval { check_query_nodes(GraphQL::Houtou::parse($cyclic), max_nodes => 100); 1 };
  ok $ok, 'a self-referential fragment does not loop the counter';
};

subtest 'the request stage enforces the node cap' => sub {
  my $runtime = build_native_runtime($schema, max_nodes => 100);

  my $flooded = $runtime->execute_document(flood(200));
  ok !exists $flooded->{data}, 'over the cap: errors-only envelope';
  like $flooded->{errors}[0]{message}, qr/too many field selections/, 'the node-limit message';

  my $ok = $runtime->execute_document(flood(50));
  ok !exists $ok->{errors}, 'under the cap: no errors';
  is scalar keys %{ $ok->{data} }, 50, 'under the cap resolves every alias';

  my $off = $runtime->execute_document(flood(200), max_nodes => undef);
  ok exists $off->{data}, 'per-call max_nodes => undef bypasses the cap';
};

subtest 'the default cap admits ordinary and introspection queries' => sub {
  my $runtime = build_native_runtime($schema);
  my $plain = $runtime->execute_document('{ hello }');
  ok !exists $plain->{errors}, 'a plain query';
  my $introspection = $runtime->execute_document(
    '{ __schema { queryType { name } } }',
  );
  ok !exists $introspection->{errors},
    'a schema introspection query';
};

done_testing;
