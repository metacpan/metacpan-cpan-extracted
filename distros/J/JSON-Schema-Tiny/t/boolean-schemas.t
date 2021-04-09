use strict;
use warnings;
use 5.016;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use JSON::Schema::Tiny 'evaluate';
use lib 't/lib';
use Helper;

my @tests = (
  { schema => false, result => false },
  { schema => true, result => true },
  { schema => {}, result => true },
  { schema => 0, result => false },
  { schema => 1, result => false },
  { schema => \0, result => false },
  { schema => \1, result => false },
);

BOOLEAN_TESTS:
note '$MOJO_BOOLEANS = '.(0+!!$JSON::Schema::Tiny::MOJO_BOOLEANS);
foreach my $test (@tests) {
  my $data = 'hello';
  is(
    exception {
      my $result = evaluate($data, $test->{schema});
      cmp_deeply(
        $result,
        {
          valid => $test->{result},
          $test->{result} ? () : (errors => supersetof()),
        },
        'invalid result structure looks correct',
      );

      local $JSON::Schema::Tiny::BOOLEAN_RESULT = 1;
      my $bool_result = evaluate($data, $test->{schema});
      ok(!($bool_result xor $test->{result}), json_sprintf('schema: %s evaluates to: %s', $test->{schema}, $test->{result}));
    },
    undef,
    'no exceptions in evaluate',
  );
}

if (not $JSON::Schema::Tiny::MOJO_BOOLEANS) {
  # schemas still do not accept mojo booleans
  $JSON::Schema::Tiny::MOJO_BOOLEANS = 1;
  goto BOOLEAN_TESTS;
}

cmp_deeply(
  evaluate('hello', []),
  {
    valid => false,
    errors => [
      {
        instanceLocation => '',
        keywordLocation => '',
        error => 'invalid schema type: array',
      },
    ],
  },
  'array for schema results in error',
);

cmp_deeply(
  evaluate('hello', \0),
  {
    valid => false,
    errors => [
      {
        instanceLocation => '',
        keywordLocation => '',
        error => 'invalid schema type: reference to SCALAR',
      },
    ],
  },
  'scalarref for schema results in error, even when $MOJO_BOOLEANS is true',
);

done_testing;
