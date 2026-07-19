use strict;
use warnings;
use Test::More 0.98;

# execute_document's error taxonomy (P0-4): request errors - syntax,
# validation, input coercion - return an errors-only envelope (no "data"
# key) instead of raising exceptions, while configuration and internal
# errors keep propagating as exceptions. Field errors are unaffected: they
# stay inside a response with data.

use JSON::PP ();

use GraphQL::Houtou qw(build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String $Int);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      hello => {
        type => $String,
        args => { name => { type => $String->non_null } },
        resolve => sub { 'hi ' . $_[1]{name} },
      },
      count => {
        type => $Int,
        args => { n => { type => $Int } },
        resolve => sub { $_[1]{n} },
      },
      boom => { type => $String, resolve => sub { die "kaboom\n" } },
    },
  ),
);

sub runtime { build_native_runtime($schema, program_cache_max => 100, @_) }

subtest 'syntax errors return an envelope with a clean message' => sub {
  my $result = runtime()->execute_document('{ hello( }');
  ok !exists $result->{data}, 'no data key';
  like $result->{errors}[0]{message}, qr/\ASyntax Error: /,
    'Pegex internals are reformatted';
  unlike $result->{errors}[0]{message}, qr/Pegex|position:/,
    'parser internals do not leak';
  ok $result->{errors}[0]{locations}[0]{line}, 'locations preserved';
};

subtest 'variable coercion failures are request errors' => sub {
  my $runtime = runtime();
  my $query = 'query Q($n: String!) { hello(name: $n) }';

  my $missing = $runtime->execute_document($query, variables => {});
  ok !exists $missing->{data}, 'no data key for a missing non-null variable';
  is $missing->{errors}[0]{message},
    'Variable "$n" of required type "String!" was not provided.',
    'missing variable names the variable and its declared type';

  my $null = $runtime->execute_document($query, variables => { n => undef });
  is $null->{errors}[0]{message},
    'Variable "$n" got invalid value null; String! given null value.',
    'explicit null carries the variable context';

  my $wrong = $runtime->execute_document($query, variables => { n => [1] });
  like $wrong->{errors}[0]{message},
    qr/\AVariable "\$n" got invalid value \(reference\); Not a String/,
    'wrong shape names the variable and renders the value';

  my $ok = $runtime->execute_document($query, variables => { n => 'Ana' });
  is $ok->{data}{hello}, 'hi Ana', 'the same cached document still executes';
};

subtest 'variable error values are rendered bounded and escaped' => sub {
  my $runtime = runtime();
  my $query = 'query Q($n: Int) { count(n: $n) }';

  my $string = $runtime->execute_document($query, variables => { n => 'abc' });
  is $string->{errors}[0]{message},
    'Variable "$n" got invalid value "abc"; Not an Int.',
    'string values are quoted';

  my $quotes = $runtime->execute_document($query, variables => { n => q{a"b\\c} });
  is $quotes->{errors}[0]{message},
    'Variable "$n" got invalid value "a\\"b\\\\c"; Not an Int.',
    'quotes and backslashes are escaped';

  my $long = $runtime->execute_document($query, variables => { n => 'z' x 200 });
  is $long->{errors}[0]{message},
    'Variable "$n" got invalid value "' . ('z' x 64) . '..."; Not an Int.',
    'long values are truncated with an ellipsis';

  my $wide = $runtime->execute_document($query,
    variables => { n => "\x{65e5}" x 40 });
  like $wide->{errors}[0]{message},
    qr/\AVariable "\$n" got invalid value "\x{65e5}+\.\.\."; Not an Int\.\z/,
    'multi-byte values are truncated on a character boundary';
};

subtest 'resolver failures stay field errors inside a data response' => sub {
  my $result = runtime()->execute_document('{ boom }');
  ok exists $result->{data}, 'data key present';
  is $result->{data}{boom}, undef, 'failed field is null';
  is_deeply $result->{errors}[0]{path}, ['boom'], 'field error carries a path';
};

subtest 'configuration errors keep raising exceptions' => sub {
  eval { require Promise::XS; 1 } or plan skip_all => 'Promise::XS not available';
  my $async_schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        later => { type => $String, resolve => sub { Promise::XS::resolved('x') } },
      },
    ),
  );
  my $sync_runtime = build_native_runtime($async_schema);
  eval { $sync_runtime->execute_document_to_json('{ later }') };
  like $@, qr/async => 1/, 'async misconfiguration is an exception, not an envelope';
};

subtest 'the JSON lane mirrors the envelope taxonomy' => sub {
  my $runtime = runtime();
  my $json = JSON::PP->new->utf8;

  my $syntax = $json->decode($runtime->execute_document_to_json('{ hello( }'));
  ok !exists $syntax->{data}, 'syntax error: no data key';
  like $syntax->{errors}[0]{message}, qr/\ASyntax Error: /, 'syntax error message';

  my $coercion = $json->decode($runtime->execute_document_to_json(
    'query Q($n: String!) { hello(name: $n) }', variables => {},
  ));
  ok !exists $coercion->{data}, 'coercion error: no data key';
  like $coercion->{errors}[0]{message},
    qr/\AVariable "\$n" of required type "String!" was not provided\./,
    'coercion message carries the variable context';

  my $field = $json->decode($runtime->execute_document_to_json('{ boom }'));
  ok exists $field->{data}, 'field error keeps data';
};

done_testing;
