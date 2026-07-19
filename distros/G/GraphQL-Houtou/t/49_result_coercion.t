use strict;
use warnings;
use Test::More 0.98;

# Leaf result coercion (P0-3, spec 6.4.3): resolver output is checked and
# serialized against the field's leaf type at completion time on every
# lane. Ints must be int32 (numeric strings coerce), Floats numeric,
# String/ID stringify plain scalars, Enums map internal values to names
# and reject non-members, custom scalars run their serialize callback.
# Failures null the field (or list item) and record a field error with
# the item index in the path.

use JSON::PP ();

use GraphQL::Houtou qw(build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Enum;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($Float $Int $String);

my $Mood = GraphQL::Houtou::Type::Enum->new(
  name => 'Mood',
  values => {
    HAPPY => {},
    GRIM => { value => 'internal-grim' },
  },
);

my $Upper = GraphQL::Houtou::Type::Scalar->new(
  name => 'Upper',
  serialize => sub { defined $_[0] ? uc $_[0] : undef },
  parse_value => sub { $_[0] },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      numString => { type => $Int, resolve => sub { '5' } },
      numBad => { type => $Int, resolve => sub { 'abc' } },
      numFloat => { type => $Int, resolve => sub { 1.5 } },
      numBig => { type => $Int, resolve => sub { 2**33 } },
      floatOk => { type => $Float, resolve => sub { '1.25' } },
      strNum => { type => $String, resolve => sub { 12345 } },
      strRef => { type => $String, resolve => sub { +{} } },
      moodMapped => { type => $Mood, resolve => sub { 'internal-grim' } },
      moodBad => { type => $Mood, resolve => sub { 'ANGRY' } },
      up => { type => $Upper, resolve => sub { 'quiet' } },
      upDies => { type => $Upper, resolve => sub { \'ref' } },
      nums => { type => $Int->list, resolve => sub { [ 1, 'x', '3' ] } },
      moods => { type => $Mood->list, resolve => sub { [ 'HAPPY', 'NOPE' ] } },
    },
  ),
  types => [ $Mood, $Upper ],
);

my $UpperDies = GraphQL::Houtou::Type::Scalar->new(
  name => 'Upper',
  serialize => sub { ref $_[0] ? die "not a word\n" : uc $_[0] },
  parse_value => sub { $_[0] },
);

my $QUERY = '{ numString numBad numFloat numBig floatOk strNum moodMapped moodBad up nums moods }';
my %EXPECTED_DATA = (
  numString => 5,
  numBad => undef,
  numFloat => undef,
  numBig => undef,
  floatOk => 1.25,
  strNum => '12345',
  moodMapped => 'GRIM',
  moodBad => undef,
  up => 'QUIET',
  nums => [ 1, undef, 3 ],
  moods => [ 'HAPPY', undef ],
);
my %EXPECTED_ERRORS = (
  'numBad' => qr/Int cannot represent non-integer value: abc/,
  'numFloat' => qr/Int cannot represent non-integer value/,
  'numBig' => qr/Int cannot represent non-integer value/,
  'moodBad' => qr/Enum 'Mood' cannot represent value: ANGRY/,
  'nums.1' => qr/Int cannot represent non-integer value: x/,
  'moods.1' => qr/Enum 'Mood' cannot represent value: NOPE/,
);

sub check_result {
  my ($label, $result) = @_;
  subtest $label => sub {
    for my $field (sort keys %EXPECTED_DATA) {
      is_deeply $result->{data}{$field}, $EXPECTED_DATA{$field}, "$field value";
    }
    my %by_path = map { (join('.', @{ $_->{path} }) => $_->{message}) } @{ $result->{errors} };
    for my $path (sort keys %EXPECTED_ERRORS) {
      like $by_path{$path}, $EXPECTED_ERRORS{$path}, "$path error";
    }
    is scalar @{ $result->{errors} }, scalar keys %EXPECTED_ERRORS, 'no extra errors';
  };
}

my $json = JSON::PP->new->utf8;

subtest 'async auto lane' => sub {
  check_result('envelope', build_native_runtime($schema, program_cache_max => 10)->execute_document($QUERY));
};

subtest 'sync fast SV lane' => sub {
  check_result('envelope', build_native_runtime($schema, program_cache_max => 10)
    ->execute_document($QUERY, variables => {}));
};

subtest 'JSON lanes serialize coerced values' => sub {
  my $runtime = build_native_runtime($schema, program_cache_max => 10);
  my $bytes = $runtime->execute_document_to_json($QUERY);
  like $bytes, qr/"numString":5[,}]/, 'numeric string emits a JSON number';
  like $bytes, qr/"strNum":"12345"/, 'number for a String field emits a JSON string';
  like $bytes, qr/"moodMapped":"GRIM"/, 'enum internal value maps to its name';
  check_result('decoded envelope', $json->decode($bytes));
};

subtest 'bundle lane' => sub {
  my $runtime = build_native_runtime($schema, program_cache_max => 10);
  my $bundle = $runtime->compile_bundle_for_document($QUERY);
  check_result('envelope', $runtime->execute_bundle($bundle));
  check_result('json', $json->decode($runtime->execute_bundle_to_json($bundle)));
};

subtest 'promise-settled leaves coerce at settle time' => sub {
  eval { require Promise::XS; 1 } or plan skip_all => 'Promise::XS not available';
  my $async_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        pNum => { type => $Int, resolve => sub { Promise::XS::resolved('7') } },
        pBad => { type => $Int, resolve => sub { Promise::XS::resolved('abc') } },
        pNums => {
          type => $Int->list,
          resolve => sub { [ Promise::XS::resolved(1), Promise::XS::resolved('x') ] },
        },
      },
    ),
  );
  my $runtime = build_native_runtime($async_schema, async => 1);
  my $result = $runtime->execute_document('{ pNum pBad pNums }', on_stall => sub { 0 });
  is_deeply $result->{data}, { pNum => 7, pBad => undef, pNums => [ 1, undef ] },
    'promise leaves coerce';
  my %by_path = map { (join('.', @{ $_->{path} }) => 1) } @{ $result->{errors} };
  ok $by_path{'pBad'} && $by_path{'pNums.1'}, 'errors carry field and item paths';
};

subtest 'custom scalar serialize failure is a field error' => sub {
  my $dies_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        upDies => { type => $UpperDies, resolve => sub { \'ref' } },
      },
    ),
    types => [ $UpperDies ],
  );
  my $result = build_native_runtime($dies_schema, program_cache_max => 10)
    ->execute_document('{ upDies }');
  is $result->{data}{upDies}, undef, 'field nulled';
  like $result->{errors}[0]{message}, qr/not a word/, 'serialize die becomes a field error';
};

done_testing;
