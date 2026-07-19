use strict;
use warnings;

use Test::More;
use JSON::PP ();

use GraphQL::Houtou qw(execute execute_to_json);
use GraphQL::Houtou::PSGI;
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

my $subscription_calls = 0;
my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => { ping => { type => $String, resolve => sub { 'pong' } } },
  ),
  subscription => GraphQL::Houtou::Type::Object->new(
    name => 'Subscription',
    fields => {
      updates => {
        type => $String,
        resolve => sub { $subscription_calls++; return 'unexpected' },
      },
    },
  ),
);

sub assert_unsupported {
  my ($result, $label) = @_;
  ok !exists($result->{data}), "$label has no data";
  is $result->{errors}[0]{message}, 'Subscription execution is not supported.',
    "$label reports unsupported execution";
  is $result->{errors}[0]{extensions}{code}, 'SUBSCRIPTION_NOT_SUPPORTED',
    "$label exposes a machine-readable code";
}

subtest 'public execution APIs fail closed before resolving fields' => sub {
  assert_unsupported execute($schema, 'subscription S { updates }'), 'execute';
  assert_unsupported JSON::PP::decode_json(
    execute_to_json($schema, 'subscription S { updates }')
  ), 'execute_to_json';
  is $subscription_calls, 0, 'subscription resolver was never called';

  my $query = execute($schema, '{ ping }');
  is_deeply $query, { data => { ping => 'pong' } },
    'query execution remains available';
};

subtest 'runtime rejects subscriptions even when validation is disabled' => sub {
  my $runtime = $schema->build_native_runtime(
    validate => 0, program_cache_max => 10,
  );
  assert_unsupported $runtime->execute_document('subscription S { updates }'),
    'validate-disabled runtime';
  is $runtime->program_cache_size, 0,
    'unsupported operation never enters the program cache';

  my $document = 'query Q { ping } subscription S { updates }';
  assert_unsupported $runtime->execute_document(
    $document, operation_name => 'S',
  ), 'named subscription operation';
  is $runtime->execute_document($document, operation_name => 'Q')->{data}{ping},
    'pong', 'named query operation remains executable';
  is $subscription_calls, 0, 'runtime paths did not call the resolver';
};

subtest 'PSGI maps unsupported subscriptions to a request error' => sub {
  my $app = GraphQL::Houtou::PSGI->new(schema => $schema)->to_app;
  my $body = JSON::PP::encode_json({ query => 'subscription S { updates }' });
  open my $input, '<', \$body or die $!;
  my $response = $app->({
    REQUEST_METHOD => 'POST',
    CONTENT_TYPE => 'application/json',
    CONTENT_LENGTH => length($body),
    HTTP_ACCEPT => 'application/graphql-response+json',
    'psgi.input' => $input,
  });
  is $response->[0], 400, 'unsupported subscription is HTTP 400';
  my $result = JSON::PP::decode_json(join q(), @{ $response->[2] });
  assert_unsupported $result, 'PSGI response';
  is $subscription_calls, 0, 'PSGI path did not call the resolver';
};

subtest 'persisted descriptors cannot bypass the subscription guard' => sub {
  my $runtime = $schema->build_native_runtime;
  my $program_descriptor = $runtime->compile_program_descriptor_for_document('{ ping }');
  $program_descriptor->{operation_type_code} = 3;

  my $ok = eval {
    $schema->build_runtime->inflate_program($program_descriptor);
    1;
  };
  ok !$ok, 'subscription program descriptor rejected before XS loading';
  isa_ok $@, 'GraphQL::Houtou::Error';
  is $@->extensions->{code}, 'SUBSCRIPTION_NOT_SUPPORTED',
    'program descriptor rejection keeps the public error code';

  my $bundle_descriptor = $runtime->compile_bundle_descriptor_for_document('{ ping }');
  $bundle_descriptor->{program}{operation_type_code} = 3;
  for my $case (
    [ load => sub { $runtime->load_bundle_descriptor($bundle_descriptor) } ],
    [ inflate => sub { $runtime->inflate_bundle_descriptor($bundle_descriptor) } ],
    [ execute => sub { $runtime->execute_bundle_descriptor($bundle_descriptor) } ],
  ) {
    my ($label, $run) = @$case;
    my $loaded = eval { $run->(); 1 };
    ok !$loaded, "$label rejects a subscription bundle descriptor";
    isa_ok $@, 'GraphQL::Houtou::Error';
    is $@->extensions->{code}, 'SUBSCRIPTION_NOT_SUPPORTED',
      "$label keeps the public error code";
  }
};

done_testing;
