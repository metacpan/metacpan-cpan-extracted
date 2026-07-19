use strict;
use warnings;

use Test::More;
use JSON::MaybeXS ();

use GraphQL::Houtou qw(build_schema execute execute_to_json build_native_runtime compile_native_bundle);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Union;
use GraphQL::Houtou::Type::Scalar qw($String $Int $Float $Boolean $ID);

my $json = JSON::MaybeXS->new->utf8;

my $User = GraphQL::Houtou::Type::Object->new(
  name => 'User',
  runtime_tag => 'user',
  fields => {
    id => { type => $ID },
    name => { type => $String },
  },
);

my $Thing = GraphQL::Houtou::Type::Union->new(
  name => 'Thing',
  types => [ $User ],
  tag_resolver => sub { 'user' },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      str => { type => $String, resolve => sub { qq{he said "hi"\n\ttab \x{3042}} } },
      int => { type => $Int, resolve => sub { 42 } },
      float => { type => $Float, resolve => sub { 2.5 } },
      bool => { type => $Boolean, resolve => sub { 1 } },
      nothing => { type => $String, resolve => sub { undef } },
      numeric_string => { type => $String, resolve => sub { '00123' } },
      user => {
        type => $User,
        args => { id => { type => $ID } },
        resolve => sub { my (undef, $args) = @_; { id => $args->{id} // '1', name => 'alice' } },
      },
      users => {
        type => $User->non_null->list,
        resolve => sub { [ { id => '1', name => 'a' }, { id => '2', name => 'b' } ] },
      },
      tags => { type => $String->list, resolve => sub { [ 'x', undef, 'y' ] } },
      thing => { type => $Thing, resolve => sub { { id => '9', name => 'u9' } } },
      boom => { type => $String, resolve => sub { die "boom\n" } },
    },
  ),
  types => [ $User, $Thing ],
);

my $runtime = build_native_runtime($schema);

sub json_matches_execute {
  my ($query, %opts) = @_;
  my $bytes = $runtime->execute_document_to_json($query, %opts);
  my $decoded = $json->decode($bytes);
  my $reference = $runtime->execute_document($query, %opts);
  is_deeply $decoded, $reference,
    "to_json round-trips execute for $query";
  return $bytes;
}

subtest 'scalar kinds serialize with correct JSON types' => sub {
  # str is asserted on raw bytes below instead of via the round-trip
  # comparison: the SV-lane reference copy does not always preserve the
  # UTF8 flag, which makes eq-deep comparisons encoding-form sensitive.
  json_matches_execute('{ int float bool nothing numeric_string }');
  my $bytes = $runtime->execute_document_to_json('{ str int float bool nothing numeric_string }');
  like $bytes, qr/"int":42[,}]/, 'Int is a bare JSON number';
  like $bytes, qr/"float":2\.5[,}]/, 'Float is a bare JSON number';
  like $bytes, qr/"bool":true[,}]/, 'Boolean is a JSON boolean';
  like $bytes, qr/"nothing":null[,}]/, 'undef is null';
  like $bytes, qr/"numeric_string":"00123"[,}]/, 'string stays a string';
  like $bytes, qr/\\"hi\\"/, 'quotes escaped';
  like $bytes, qr/\\n\\ttab/, 'control characters escaped';
  my $aiueo = "\x{3042}";
  utf8::encode($aiueo);
  like $bytes, qr/\Q$aiueo\E/, 'non-ASCII passes through as UTF-8 bytes';
  ok !utf8::is_utf8($bytes), 'output is octets, not a character string';
  is $json->decode($bytes)->{data}{str}, qq{he said "hi"\n\ttab \x{3042}},
    'decoded string round-trips the resolver value';
};

subtest 'objects, lists, and abstract types' => sub {
  json_matches_execute('{ user(id: "7") { id name } }');
  json_matches_execute('{ users { id name } }');
  json_matches_execute('{ tags }');
  json_matches_execute('{ thing { __typename ... on User { id name } } }');
};

subtest 'field order follows the query' => sub {
  my $bytes = $runtime->execute_document_to_json('{ int str bool }');
  like $bytes, qr/\{"data":\{"int":.*"str":.*"bool":/s, 'response keys in query order';
  my $bytes2 = $runtime->execute_document_to_json('{ bool str int }');
  like $bytes2, qr/\{"data":\{"bool":.*"str":.*"int":/s, 'order changes with the query';
};

subtest 'aliases and variables' => sub {
  my $bytes = json_matches_execute('{ a: int b: int }');
  like $bytes, qr/"a":42,"b":42/, 'aliases are response keys';
  json_matches_execute('query Q($id: ID) { user(id: $id) { id } }', variables => { id => '33' });
  my $with_vars = $runtime->execute_document_to_json(
    'query Q($id: ID) { user(id: $id) { id } }', variables => { id => '99' },
  );
  like $with_vars, qr/"id":"99"/, 'variables reach resolvers';
};

subtest 'errors serialize with message and path' => sub {
  my $bytes = json_matches_execute('{ boom int }');
  my $decoded = $json->decode($bytes);
  is $decoded->{data}{boom}, undef, 'errored field is null';
  is $decoded->{data}{int}, 42, 'sibling field still resolves';
  is $decoded->{errors}[0]{message}, 'boom', 'error message';
  is_deeply $decoded->{errors}[0]{path}, ['boom'], 'error path';
};

subtest 'bundle variant' => sub {
  my $bundle = compile_native_bundle($schema, '{ users { id name } }');
  my $bytes = $runtime->execute_bundle_to_json($bundle);
  is_deeply $json->decode($bytes), $runtime->execute_bundle($bundle),
    'bundle to_json matches execute_bundle';
};

subtest 'top-level execute_to_json' => sub {
  my $bytes = execute_to_json($schema, '{ int }');
  is_deeply $json->decode($bytes), { data => { int => 42 } }, 'convenience wrapper works';
};

subtest 'introspection query smoke' => sub {
  require GraphQL::Houtou::Introspection;
  my $bytes = $runtime->execute_document_to_json($GraphQL::Houtou::Introspection::QUERY);
  my $decoded = $json->decode($bytes);
  ok !exists $decoded->{errors}, 'no errors on full introspection';
  ok $decoded->{data}{__schema}{types}, 'introspection tree serializes';
};

subtest 'async resolvers need an async runtime' => sub {
  my $has_promise_xs = eval { require Promise::XS; 1 };
  plan skip_all => 'Promise::XS not available' if !$has_promise_xs;
  my $async_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'AsyncQuery',
      fields => {
        later => { type => $String, resolve => sub { Promise::XS::resolved('x') } },
      },
    ),
  );
  my $rt = build_native_runtime($async_schema);
  eval { $rt->execute_document_to_json('{ later }') };
  like $@, qr/async => 1/, 'sync runtime rejects promises with the async => 1 hint';

  my $rt_async = build_native_runtime($async_schema, async => 1);
  my $bytes = $rt_async->execute_document_to_json('{ later }');
  is_deeply $json->decode($bytes), { data => { later => 'x' } },
    'async runtime settles pre-resolved promises to JSON';
};

subtest 'sequential responses are stable' => sub {
  my $first = $runtime->execute_document_to_json('{ users { id name } int }');
  my $second = $runtime->execute_document_to_json('{ users { id name } int }');
  is $second, $first, 'identical bytes across requests';
};

done_testing;
