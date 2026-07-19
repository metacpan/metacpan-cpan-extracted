use strict;
use warnings;
use Test::More;
use JSON::PP ();

use GraphQL::Houtou qw(build_native_runtime execute_to_json);
use GraphQL::Houtou::DataLoader;
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String $ID $Int);

BEGIN {
  eval { require Promise::XS; 1 }
    or plan skip_all => 'Promise::XS is required for async execution tests';
}

my @batch_calls;

my $User = GraphQL::Houtou::Type::Object->new(
  name => 'User',
  fields => {
    name => { type => $String },
    age  => { type => $Int },
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      user => {
        type => $User,
        args => { id => { type => $ID } },
        resolve => sub {
          my (undef, $args, $context) = @_;
          return $context->{users}->load($args->{id});
        },
      },
      plain => { type => $String, resolve => sub { 'sync-value' } },
      boom => { type => $String, resolve => sub { die "kaboom\n" } },
    },
  ),
);

my $runtime = build_native_runtime($schema);

sub new_loader {
  return GraphQL::Houtou::DataLoader->new(batch => sub {
    my ($ids) = @_;
    push @batch_calls, [@$ids];
    return [ map { { name => "user-$_", age => 30 } } @$ids ];
  });
}

sub decode { JSON::PP::decode_json($_[0]) }

subtest 'async request renders JSON directly' => sub {
  @batch_calls = ();
  my $users = new_loader();
  my $json = $runtime->execute_document_to_json(
    'query Q($id: ID) { a: user(id: $id) { name age } b: user(id: "u2") { name } plain }',
    variables => { id => 'u1' },
    context => { users => $users },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users),
  );
  ok !ref $json, 'returns a JSON string, not a promise or hash';
  my $res = decode($json);
  is_deeply $res, {
    data => {
      a => { name => 'user-u1', age => 30 },
      b => { name => 'user-u2' },
      plain => 'sync-value',
    },
  }, 'envelope matches the SV lane result';
  is scalar @batch_calls, 1, 'N+1 collapsed into a single batch';
  is_deeply [ sort @{ $batch_calls[0] } ], [qw(u1 u2)], 'both keys batched together';
};

subtest 'matches execute_document envelope' => sub {
  my $users_sv = new_loader();
  my $sv = $runtime->execute_document(
    'query Q($id: ID) { user(id: $id) { name age } plain }',
    variables => { id => 'u9' },
    context => { users => $users_sv },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users_sv),
  );
  my $users_json = new_loader();
  my $json = $runtime->execute_document_to_json(
    'query Q($id: ID) { user(id: $id) { name age } plain }',
    variables => { id => 'u9' },
    context => { users => $users_json },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users_json),
  );
  is_deeply decode($json), $sv, 'JSON decodes to the same structure';
};

subtest 'resolver errors are captured with paths' => sub {
  my $users = new_loader();
  my $json = $runtime->execute_document_to_json(
    '{ boom plain user(id: "x") { name } }',
    context => { users => $users },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users),
  );
  my $res = decode($json);
  is $res->{data}{boom}, undef, 'failed field is null';
  is $res->{data}{plain}, 'sync-value', 'sibling sync field survives';
  is $res->{data}{user}{name}, 'user-x', 'sibling async field survives';
  is scalar @{ $res->{errors} }, 1, 'one error recorded';
  is $res->{errors}[0]{message}, 'kaboom', 'error message preserved';
  is_deeply $res->{errors}[0]{path}, ['boom'], 'error path preserved';
};

subtest 'all-sync request with on_stall still returns JSON' => sub {
  my $json = $runtime->execute_document_to_json(
    '{ plain }',
    on_stall => sub { 0 },
  );
  is_deeply decode($json), { data => { plain => 'sync-value' } },
    'sync completion renders the same envelope';
};

subtest 'deadlock is detected' => sub {
  my $users = GraphQL::Houtou::DataLoader->new(batch => sub { [ map { {} } @{ $_[0] } ] });
  my $err = do {
    local $@;
    eval {
      $runtime->execute_document_to_json(
        '{ user(id: "u1") { name } }',
        context => { users => $users },
        on_stall => sub { 0 },
      );
    };
    $@;
  };
  like $err, qr/stalled/, 'no-progress stall dies with the deadlock error';
};

subtest 'nested structures behind a promise keep their shape in JSON' => sub {
  # Regression: the outcome->native conversion wrapped nested plain
  # hash/array trees one level deep as scalars, so a promise-of-list (or a
  # promise-of-object with nested children) serialized items as the string
  # "HASH(0x...)" on the JSON lane.
  my $Inner = GraphQL::Houtou::Type::Object->new(
    name => 'Inner', fields => { city => { type => $String } });
  my $Row = GraphQL::Houtou::Type::Object->new(
    name => 'Row',
    fields => {
      name => { type => $String },
      qty => { type => $Int },
      inner => { type => $Inner },
    },
  );
  my $make_rows = sub {
    [ map { my $i = $_;
        { name => "r$i", qty => 0 + $i, inner => { city => "c$i" } } } 1 .. 2 ];
  };
  my $async_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        rows => {
          type => $Row->list,
          resolve => sub { Promise::XS::resolved($make_rows->()) },
        },
        row => {
          type => $Row,
          resolve => sub { Promise::XS::resolved($make_rows->()->[0]) },
        },
      },
    ),
  );
  my $rt = build_native_runtime($async_schema, async => 1);
  my $json = $rt->execute_document_to_json(
    '{ rows { name qty inner { city } } row { inner { city } } }');
  is_deeply decode($json), {
    data => {
      rows => [
        { name => 'r1', qty => 1, inner => { city => 'c1' } },
        { name => 'r2', qty => 2, inner => { city => 'c2' } },
      ],
      row => { inner => { city => 'c1' } },
    },
  }, 'promise-of-list and promise-of-object serialize nested children';
};

subtest 'top-level execute_to_json accepts on_stall' => sub {
  my $users = new_loader();
  my $json = execute_to_json(
    $schema,
    'query Q($id: ID) { user(id: $id) { name } }',
    { id => 'u5' },
    context => { users => $users },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users),
  );
  is_deeply decode($json), {
    data => { user => { name => 'user-u5' } },
  }, 'sugar entrypoint drives the async JSON lane';
};

done_testing;
