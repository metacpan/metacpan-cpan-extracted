use strict;
use warnings;
use Test::More 0.98;

# Non-Null propagation (P0-2, spec 6.4.4) across every execution lane:
# a null in a non-null position records "Cannot return null for
# non-nullable field Parent.field." and nulls the enclosing object; a
# null item in a [T!] list nulls the whole list; the null bubbles to the
# nearest nullable position, reaching data:null when the entire chain is
# non-null. A null that already carries a field error (resolver die,
# coercion failure) propagates without stacking a second message.
#
# Cross-lane cases use single-violation shapes: on multiple violations
# the sync lanes stop at the first one while the async lane completes
# every field before assembling, so their error counts legitimately
# differ (both are spec-conformant; fields are semantically parallel).

use JSON::PP ();

use GraphQL::Houtou qw(build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($Int $String);

my $Inner = GraphQL::Houtou::Type::Object->new(
  name => 'Inner',
  fields => {
    req => { type => $String->non_null, resolve => sub { undef } },
    reqBoom => { type => $String->non_null, resolve => sub { die "boom\n" } },
    reqBad => { type => $Int->non_null, resolve => sub { 'abc' } },
    ok => { type => $String, resolve => sub { 'v' } },
  },
);

my $Wrap = GraphQL::Houtou::Type::Object->new(
  name => 'Wrap',
  fields => {
    inner => { type => $Inner->non_null, resolve => sub { {} } },
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      inner => { type => $Inner, resolve => sub { {} } },
      wrap => { type => $Wrap, resolve => sub { {} } },
      reqTop => { type => $String->non_null, resolve => sub { undef } },
      okSib => { type => $String, resolve => sub { 'sib' } },
      listNN => {
        type => $Inner->non_null->list,
        resolve => sub { [ {} ] },
      },
      numsNN => {
        type => $Int->non_null->list,
        resolve => sub { [ 1, undef, 3 ] },
      },
      numsOK => {
        type => $Int->list,
        resolve => sub { [ 1, undef, 3 ] },
      },
    },
  ),
);

my $CANNOT = sub { qr/\ACannot return null for non-nullable field \Q$_[0]\E\.\z/ };

# query => [expected data, expected errors as [path, message-regex]]
my %CASES = (
  'null non-null leaf nulls the enclosing object' => [
    '{ inner { req ok } okSib }',
    { inner => undef, okSib => 'sib' },
    [ [ [ 'inner', 'req' ], $CANNOT->('Inner.req') ] ],
  ],
  'propagation continues through non-null parents' => [
    '{ wrap { inner { req } } okSib }',
    { wrap => undef, okSib => 'sib' },
    [ [ [ 'wrap', 'inner', 'req' ], $CANNOT->('Inner.req') ] ],
  ],
  'null item in [T!] nulls the list' => [
    '{ numsNN okSib }',
    { numsNN => undef, okSib => 'sib' },
    [ [ [ 'numsNN', 1 ], $CANNOT->('Query.numsNN') ] ],
  ],
  'null item in a nullable-item list stays in place' => [
    '{ numsOK okSib }',
    { numsOK => [ 1, undef, 3 ], okSib => 'sib' },
    [],
  ],
  'object item violation nulls the [Inner!] list' => [
    '{ listNN { req } okSib }',
    { listNN => undef, okSib => 'sib' },
    [ [ [ 'listNN', 0, 'req' ], $CANNOT->('Inner.req') ] ],
  ],
  'an all-non-null chain nulls data itself' => [
    '{ inner { ok } reqTop }',
    undef,
    [ [ [ 'reqTop' ], $CANNOT->('Query.reqTop') ] ],
  ],
  'a resolver error propagates without a second message' => [
    '{ inner { reqBoom ok } okSib }',
    { inner => undef, okSib => 'sib' },
    [ [ [ 'inner', 'reqBoom' ], qr/\Aboom\z/ ] ],
  ],
  'a coercion failure propagates without a second message' => [
    '{ inner { reqBad ok } okSib }',
    { inner => undef, okSib => 'sib' },
    [ [ [ 'inner', 'reqBad' ], qr/Int cannot represent/ ] ],
  ],
);

sub check_envelope {
  my ($label, $result, $expected_data, $expected_errors) = @_;
  subtest $label => sub {
    is_deeply $result->{data}, $expected_data, 'data shape';
    is scalar @{ $result->{errors} }, scalar @$expected_errors, 'error count'
      or diag explain $result->{errors};
    my %by_path = map { (join("\x1F", @{ $_->{path} }) => $_->{message}) } @{ $result->{errors} };
    for my $want (@$expected_errors) {
      my ($path, $message_re) = @$want;
      like $by_path{ join("\x1F", @$path) }, $message_re, 'error at ' . join('.', @$path);
    }
  };
}

my $json = JSON::PP->new->utf8;

for my $label (sort keys %CASES) {
  my ($query, $expected_data, $expected_errors) = @{ $CASES{$label} };
  subtest $label => sub {
    my $runtime = build_native_runtime($schema, program_cache_max => 100);
    my $bundle = $runtime->compile_bundle_for_document($query);
    my %lanes = (
      'async auto (no variables)' => $runtime->execute_document($query),
      'fast SV (with variables)' => $runtime->execute_document($query, variables => {}),
      'fast JSON (no variables)' => $json->decode($runtime->execute_document_to_json($query)),
      'fast JSON (with variables)' => $json->decode($runtime->execute_document_to_json($query, variables => {})),
      'bundle envelope' => $runtime->execute_bundle($bundle),
      'bundle JSON' => $json->decode($runtime->execute_bundle_to_json($bundle)),
    );
    for my $lane (sort keys %lanes) {
      check_envelope($lane, $lanes{$lane}, $expected_data, $expected_errors);
    }
  };
}

subtest 'DataLoader-backed non-null fields propagate at settle time' => sub {
  eval { require Promise::XS; 1 } or plan skip_all => 'Promise::XS not available';
  my $AsyncInner = GraphQL::Houtou::Type::Object->new(
    name => 'Inner',
    fields => {
      req => { type => $String->non_null, resolve => sub { Promise::XS::resolved(undef) } },
      ok => { type => $String, resolve => sub { 'v' } },
    },
  );
  my $async_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        inner => { type => $AsyncInner, resolve => sub { Promise::XS::resolved({}) } },
        reqP => { type => $String->non_null, resolve => sub { Promise::XS::resolved(undef) } },
        numsNN => {
          type => $Int->non_null->list,
          resolve => sub { [ Promise::XS::resolved(1), Promise::XS::resolved(undef) ] },
        },
        okSib => { type => $String, resolve => sub { 'sib' } },
      },
    ),
  );
  my $runtime = build_native_runtime($async_schema, async => 1);
  my $on_stall = sub { 0 };

  check_envelope(
    'promise object with a null non-null field',
    $runtime->execute_document('{ inner { req ok } okSib }', on_stall => $on_stall),
    { inner => undef, okSib => 'sib' },
    [ [ [ 'inner', 'req' ], $CANNOT->('Inner.req') ] ],
  );
  check_envelope(
    'promise null at the root nulls data',
    $runtime->execute_document('{ reqP okSib }', on_stall => $on_stall),
    undef,
    [ [ [ 'reqP' ], $CANNOT->('Query.reqP') ] ],
  );
  check_envelope(
    'per-item promise null in [Int!] nulls the list',
    $runtime->execute_document('{ numsNN okSib }', on_stall => $on_stall),
    { numsNN => undef, okSib => 'sib' },
    [ [ [ 'numsNN', 1 ], $CANNOT->('Query.numsNN') ] ],
  );
};

done_testing;
