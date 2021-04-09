use strict;
use warnings;
use 5.016;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use JSON::Schema::Tiny 'evaluate';
use lib 't/lib';
use Helper;

subtest 'multiple types' => sub {
  cmp_deeply(
    evaluate(true, { type => ['string','number'] }),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/type',
          error => 'wrong type (expected one of string, number)',
        },
      ],
    },
    'correct error generated from type',
  );
};

subtest 'multipleOf' => sub {
  cmp_deeply(
    evaluate(3, { multipleOf => 2 }),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/multipleOf',
          error => 'value is not a multiple of 2',
        },
      ],
    },
    'correct error generated from multipleOf',
  );
};

subtest 'uniqueItems' => sub {
  cmp_deeply(
    evaluate([qw(a b c d c)], { uniqueItems => true }),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/uniqueItems',
          error => 'items at indices 2 and 4 are not unique',
        },
      ],
    },
    'correct error generated from uniqueItems',
  );
};

subtest 'allOf, not, and false schema' => sub {
  cmp_deeply(
    evaluate(
      my $data = 1,
      my $schema = { allOf => [ true, false, { not => { not => false } } ] },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/allOf/1',
          error => 'subschema is false',
        },
        {
          instanceLocation => '',
          keywordLocation => '/allOf/2/not',
          error => 'subschema is valid',
        },
        {
          instanceLocation => '',
          keywordLocation => '/allOf',
          error => 'subschemas 1, 2 are not valid',
        },
      ],
    },
    'correct errors with locations; did not collect errors inside "not"',
  );

  local $JSON::Schema::Tiny::SHORT_CIRCUIT = 1;
  cmp_deeply(
    evaluate($data, $schema),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/allOf/1',
          error => 'subschema is false',
        },
        {
          instanceLocation => '',
          keywordLocation => '/allOf',
          error => 'subschema 1 is not valid',
        },
      ],
    },
    'short-circuited results contain fewer errors',
  );
};

subtest 'anyOf keeps all errors for false paths when invalid, discards errors for false paths when valid' => sub {
  cmp_deeply(
    evaluate(
      my $data = 1,
      my $schema = { anyOf => [ false, false ] },
    ),
    my $result = {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/anyOf/0',
          error => 'subschema is false',
        },
        {
          instanceLocation => '',
          keywordLocation => '/anyOf/1',
          error => 'subschema is false',
        },
        {
          instanceLocation => '',
          keywordLocation => '/anyOf',
          error => 'no subschemas are valid',
        },
      ],
    },
    'correct errors with locations; did not collect errors inside "not"',
  );

  cmp_deeply(
    do {
      local $JSON::Schema::Tiny::SHORT_CIRCUIT = 1;
      evaluate($data, $schema)
    },
    $result,
    'short-circuited results contain the same errors (short-circuiting not possible)',
  );

  cmp_deeply(
    evaluate(1, { anyOf => [ false, true ], not => true }),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/not',
          error => 'subschema is valid',
        },
      ],
    },
    'did not collect errors from failure paths from successful anyOf',
  );

  cmp_deeply(
    evaluate(1, { anyOf => [ false, true ] }),
    { valid => true },
    'no errors collected for true validation',
  );
};

subtest 'applicators with non-boolean subschemas, discarding intermediary errors - items' => sub {
  my $result = evaluate(
    my $data = [ 1, 2 ],
    my $schema = {
      items => {
        anyOf => [
          { minimum => 2 },
          { allOf => [ { maximum => -1 }, { maximum => 0 } ] },
        ]
      },
    },
  );

# - evaluate /items on instance ''
#   - evaluate /items on instance /0
#     - evaluate /items/anyOf on instance /0
#       - evaluate /items/anyOf/0 on instance /0
#         - evaluate /items/anyOf/0/minimum on instance /0            FAIL
#         /items/anyOf/0 FAILS
#       - evaluate /items/anyOf/1 on instance /0
#         - evaluate /items/anyOf/1/allOf on instance /0
#           - evaluate /items/anyOf/1/allOf/0 on instance /0
#             - evaluate /items/anyOf/1/allOf/0/maximum on instance /0  FAIL
#           - evaluate /items/anyOf/1/allOf/1 on instance /0
#             - evaluate /items/anyOf/1/allOf/1/maximum on instance /0  FAIL
#           /items/anyOf/1/allOf FAILS
#         /items/anyOf/1 FAILS (no message)
#       /items/anyOf FAILS
#     /items FAILS on instance /0 (no message)

#   - evaluate /items on instance /1
#     - evaluate /items/anyOf on instance /1
#       - evaluate /items/anyOf/0 on instance /1
#         - evaluate /items/anyOf/0/minimum on instance /1            PASS
#         /items/anyOf/0 PASSES
#       - evaluate /items/anyOf/1 on instance /1
#         - evaluate /items/anyOf/1/allOf on instance /1
#           - evaluate /items/anyOf/1/allOf/0 on instance /1
#             - evaluate /items/anyOf/1/allOf/0/maximum on instance /1  FAIL
#           - evaluate /items/anyOf/1/allOf/1 on instance /1
#             - evaluate /items/anyOf/1/allOf/1/maximum on instance /1  FAIL
#           /items/anyOf/1/allOf FAILS
#         /items/anyOf/1 FAILS (no message)
#       /items/anyOf PASSES -- all failures above are discarded
#     /items PASSES on instance /1
#   /items FAILS (across all instances)
# entire schema FAILS

  cmp_deeply(
    $result,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/0',
          keywordLocation => '/items/anyOf/0/minimum',
          error => 'value is smaller than 2',
        },
        {
          instanceLocation => '/0',
          keywordLocation => '/items/anyOf/1/allOf/0/maximum',
          error => 'value is larger than -1',
        },
        {
          instanceLocation => '/0',
          keywordLocation => '/items/anyOf/1/allOf/1/maximum',
          error => 'value is larger than 0',
        },
        {
          instanceLocation => '/0',
          keywordLocation => '/items/anyOf/1/allOf',
          error => 'subschemas 0, 1 are not valid',
        },
        {
          instanceLocation => '/0',
          keywordLocation => '/items/anyOf',
          error => 'no subschemas are valid',
        },
        # these errors are discarded because /items/anyOf passes on instance /1
        #{
        #  instanceLocation => '/1',
        #  keywordLocation => '/items/anyOf/1/allOf/0/maximum',
        #  error => 'value is larger than -1',
        #},
        #{
        #  instanceLocation => '/1',
        #  keywordLocation => '/items/anyOf/1/allOf/1/maximum',
        #  error => 'value is larger than 0',
        #},
        #{
        #  instanceLocation => '/1',
        #  keywordLocation => '/items/anyOf/1/allOf',
        #  error => 'subschemas 0, 1 are not valid',
        #},
        {
          instanceLocation => '',
          keywordLocation => '/items',
          error => 'subschema is not valid against all items',
        },
      ],
    },
    'collected all errors from subschemas for failing branches only (passing branches discard errors)',
  );

  local $JSON::Schema::Tiny::SHORT_CIRCUIT = 1;
  cmp_deeply(
    evaluate($data, $schema),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/0',
          keywordLocation => '/items/anyOf/0/minimum',
          error => 'value is smaller than 2'
        },
        {
          instanceLocation => '/0',
          keywordLocation => '/items/anyOf/1/allOf/0/maximum',
          error => 'value is larger than -1',
        },
        {
          instanceLocation => '/0',
          keywordLocation => '/items/anyOf/1/allOf',
          error => 'subschema 0 is not valid',
        },
        {
          instanceLocation => '/0',
          keywordLocation => '/items/anyOf',
          error => 'no subschemas are valid',
        },
        {
          instanceLocation => '',
          keywordLocation => '/items',
          error => 'subschema is not valid against all items',
        },
      ],
    },
    'short-circuited results contain fewer errors',
  );
};

subtest 'applicators with non-boolean subschemas, discarding intermediary errors - contains' => sub {
  my $result = evaluate(
    my $data = [
      { foo => 1 },
      { bar => 2 },
    ],
    my $schema = {
      not => true,
      contains => {
        properties => {
          foo => false,   # if 'foo' is present, then we fail
        },
      },
    },
  );

# - evaluate /not on instance ''
#   - evaluate subschema "true" - PASS
#   /not FAILS.
# - evaluate /contains on instance ''
#   - evaluate /contains on instance /0
#     - evaluate /contains/properties on instance /0
#       - evaluate /contains/properties/foo on instance /0/foo
#         schema is FALSE.
#       /contains/properties FAILS
#     /contains does not match on instance /0
#   - evaluate /contains on instance /1
#     - evaluate /contains/properties on instance /1
#       - evaluate /contains/properties/foo on instance /1/foo - does not exist.
#         /contains/properties/foo PASSES
#       /contains/properties PASSES
#     /contains matches on instance /1
#   /contains has at least 1 match; it PASSES
# entire schema FAILS

  cmp_deeply(
    $result,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/not',
          error => 'subschema is valid',
        },
        # these errors are discarded because /contains passes on instance /1
        #{
        #  instanceLocation => '/0/foo',
        #  keywordLocation => '/contains/properties/foo',
        #  error => 'subschema is false',
        #},
        #{
        #  instanceLocation => '/0',
        #  keywordLocation => '/contains/properties',
        #  error => 'not all properties are valid',
        #},
      ],
    },
    'collected all errors from subschemas for failing branches only (passing branches discard errors)',
  );

  cmp_deeply(
    evaluate($data, $schema),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/not',
          error => 'subschema is valid',
        },
      ],
    },
    'short-circuited results contain the same errors',
  );
};

subtest 'errors with $refs' => sub {
  my $result = evaluate(
    [ { x => 1 }, { x => 2 }, { x => 3 } ],
    {
      '$defs' => {
        mydef => {
          type => 'integer',
          minimum => 5,
          '$ref' => '#/$defs/myint',
        },
        myint => {
          multipleOf => 5,
        },
      },
      items => {
        properties => {
          x => {
            '$ref' => '#/$defs/mydef',
            maximum => 2,
          },
        },
      }
    },
  );

  # evaluation order:
  # /items/properties/x/$ref (mydef) /$ref (myint) /multipleOf
  # /items/properties/x/$ref (mydef) /type
  # /items/properties/x/$ref (mydef) /minimum
  # /items/properties/x/maximum

  cmp_deeply(
    $result,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/0/x',
          keywordLocation => '/items/properties/x/$ref/$ref/multipleOf',
          absoluteKeywordLocation => '#/$defs/myint/multipleOf',
          error => 'value is not a multiple of 5',
        },
        {
          instanceLocation => '/0/x',
          keywordLocation => '/items/properties/x/$ref/minimum',
          absoluteKeywordLocation => '#/$defs/mydef/minimum',
          error => 'value is smaller than 5',
        },
        {
          instanceLocation => '/0',
          keywordLocation => '/items/properties',
          error => 'not all properties are valid',
        },
        {
          instanceLocation => '/1/x',
          keywordLocation => '/items/properties/x/$ref/$ref/multipleOf',
          absoluteKeywordLocation => '#/$defs/myint/multipleOf',
          error => 'value is not a multiple of 5',
        },
        {
          instanceLocation => '/1/x',
          keywordLocation => '/items/properties/x/$ref/minimum',
          absoluteKeywordLocation => '#/$defs/mydef/minimum',
          error => 'value is smaller than 5',
        },
        {
          instanceLocation => '/1',
          keywordLocation => '/items/properties',
          error => 'not all properties are valid',
        },
        {
          instanceLocation => '/2/x',
          keywordLocation => '/items/properties/x/$ref/$ref/multipleOf',
          absoluteKeywordLocation => '#/$defs/myint/multipleOf',
          error => 'value is not a multiple of 5',
        },
        {
          instanceLocation => '/2/x',
          keywordLocation => '/items/properties/x/$ref/minimum',
          absoluteKeywordLocation => '#/$defs/mydef/minimum',
          error => 'value is smaller than 5',
        },
        {
          instanceLocation => '/2/x',
          keywordLocation => '/items/properties/x/maximum',
          error => 'value is larger than 2',
        },
        {
          instanceLocation => '/2',
          keywordLocation => '/items/properties',
          error => 'not all properties are valid',
        },
        {
          instanceLocation => '',
          keywordLocation => '/items',
          error => 'subschema is not valid against all items',
        },
      ],
    },
    'errors have correct absolute keyword location via $ref',
  );
};

subtest 'const and enum' => sub {
  cmp_deeply(
    evaluate(
      { foo => { a => { b => { c => { d => 1 } } } } },
      {
        properties => {
          foo => {
            allOf => [
              { const => { a => { b => { c => { d => 2 } } } } },
              { enum => [ 0, 'whargarbl', { a => { b => { c => { d => 2 } } } } ] },
            ],
          }
        },
      },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/foo',
          keywordLocation => '/properties/foo/allOf/0/const',
          error => 'value does not match (differences start at "/a/b/c/d")',
        },
        {
          instanceLocation => '/foo',
          keywordLocation => '/properties/foo/allOf/1/enum',
          error => 'value does not match (differences start from item #0 at "", from item #1 at "", from item #2 at "/a/b/c/d")',
        },
        {
          instanceLocation => '/foo',
          keywordLocation => '/properties/foo/allOf',
          error => 'subschemas 0, 1 are not valid',
        },
        {
          instanceLocation => '',
          keywordLocation => '/properties',
          error => 'not all properties are valid',
        },
      ],
    },
    'got details about object differences in errors from const and enum',
  );
};

subtest 'exceptions' => sub {
  cmp_deeply(
    evaluate(
      { x => 'hello' },
      {
        allOf => [
          { properties => { x => 1 } },
          { properties => { x => false } },
        ],
      }
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/x',
          keywordLocation => '/allOf/0/properties/x',
          error => 'invalid schema type: number',
        },
      ],
    },
    'a subschema of an invalid type returns an error at the right position, and evaluation aborts',
  );

  cmp_deeply(
    evaluate(
      1,
      {
        allOf => [
          { type => 'whargarbl' },
          false,
        ],
      }
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/allOf/0/type',
          error => 'unrecognized type "whargarbl"',
        },
      ],
    },
    'invalid argument to "type" returns an error at the right position, and evaluation aborts',
  );
};

subtest 'unresolvable $ref to a local resource' => sub {
  cmp_deeply(
    evaluate(
      1,
      {
        '$ref' => '#/$defs/myint',
        '$defs' => {
          myint => {
            '$ref' => '#/$defs/does-not-exist',
          },
        },
        anyOf => [ false ],
      },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/$ref/$ref',
          absoluteKeywordLocation => '#/$defs/myint/$ref',
          error => 'EXCEPTION: unable to find resource #/$defs/does-not-exist',
        },
      ],
    },
    'error for a bad $ref reports the correct absolute location that was referred to',
  );
};

subtest 'abort due to a schema error' => sub {
  cmp_deeply(
    evaluate(
      1,
      {
        oneOf => [
          { type => 'number' },
          { type => 'string' },
          { type => 'whargarbl' },
        ],
      }
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/oneOf/2/type',
          error => 'unrecognized type "whargarbl"',
        },
      ],
    },
    'exception inside a oneOf (where errors are localized) are still included in the result',
  );
};

subtest 'sorted property names' => sub {
  cmp_deeply(
    evaluate(
      { foo => 1, bar => 1, baz => 1, hello => 1 },
      {
        properties => {
          foo => false,
          bar => false,
        },
        additionalProperties => false,
      }
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/bar',
          keywordLocation => '/properties/bar',
          error => 'property not permitted',
        },
        {
          instanceLocation => '/foo',
          keywordLocation => '/properties/foo',
          error => 'property not permitted',
        },
        {
          instanceLocation => '',
          keywordLocation => '/properties',
          error => 'not all properties are valid',
        },
        {
          instanceLocation => '/baz',
          keywordLocation => '/additionalProperties',
          error => 'additional property not permitted',
        },
        {
          instanceLocation => '/hello',
          keywordLocation => '/additionalProperties',
          error => 'additional property not permitted',
        },
        {
          instanceLocation => '',
          keywordLocation => '/additionalProperties',
          error => 'not all additional properties are valid',
        },
      ],
    },
    'property names are considered in sorted order',
  );
};

subtest 'bad regex in schema' => sub {
  cmp_deeply(
    evaluate(
      {
        my_pattern => 'foo',
      },
      my $schema = {
        type => 'object',
        properties => {
          my_pattern => {
            type => 'string',
            pattern => '(',
          },
          my_patternProperties => {
            type => 'object',
            patternProperties => { '(' => true },
            additionalProperties => false,
          },
          my_runtime_pattern => {
            type => 'string',
            pattern => '\p{main::IsFoo}', # qr/$pattern/ will not find this error, but m/$pattern/ will
          },
        },
      },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => ignore, # not important - JST errors at runtime, JSD2 at traverse time
          keywordLocation => '/properties/my_pattern/pattern',
          error => re(qr/^Unmatched \( in regex/),
        },
      ],
    },
    'bad "pattern" regex is properly noted in error',
  );

  cmp_deeply(
    evaluate(
      {
        my_patternProperties => { foo => 1 },
      },
      $schema,
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => ignore, # not important - JST errors at runtime, JSD2 at traverse time
          keywordLocation => '/properties/my_patternProperties/patternProperties/(',
          error => re(qr/^Unmatched \( in regex/),
        },
        # Note no error for missing IsFoo
      ],
    },
    'bad "patternProperties" regex is properly noted in error',
  );

  cmp_deeply(
    evaluate(
      { my_runtime_pattern => 'foo' },
      $schema,
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '', # not important - JST and JSD2 both error at runtime
          keywordLocation => '',
          # in 5.28 and earlier: Can't find Unicode property definition "IsFoo"
          # in 5.30 and later:   Unknown user-defined property name \p{main::IsFoo}
          error => re(qr/^EXCEPTION: .*property.*IsFoo/),
        },
      ],
    },
    'bad "pattern" regex is properly noted in error',
  );

  no warnings 'once';
  *IsFoo = sub { "0066\n006F\n" }; # accepts 'f', 'o'

  cmp_deeply(
    evaluate(
      { my_runtime_pattern => 'foo' },
      $schema,
    ),
    {
      valid => true,
    },
    '"pattern" regex is now valid, due to the Unicode property becoming defined',
  );
};

subtest 'JSON pointer escaping' => sub {
  cmp_deeply(
    evaluate(
      { '{}' => { 'my~tilde/slash-property' => 1 } },
      my $schema = {
        '$defs' => {
          mydef => {
            properties => {
              '{}' => {
                properties => {
                  'my~tilde/slash-property' => false,
                },
                patternProperties => {
                  '/' => { minimum => 6 },
                  '[~/]' => { minimum => 7 },
                  '~' => { minimum => 5 },
                  '~.*/' => false,
                },
              },
            },
          },
        },
        '$ref' => '#/$defs/mydef',
      },
    ),
    {
      valid => false,
      errors => my $errors = [
        {
          instanceLocation => '/{}/my~0tilde~1slash-property',
          keywordLocation => '/$ref/properties/{}/properties/my~0tilde~1slash-property',
          absoluteKeywordLocation => '#/$defs/mydef/properties/%7B%7D/properties/my~0tilde~1slash-property',
          error => 'property not permitted',
        },
        {
          instanceLocation => '/{}',
          keywordLocation => '/$ref/properties/{}/properties',
          absoluteKeywordLocation => '#/$defs/mydef/properties/%7B%7D/properties',
          error => 'not all properties are valid',
        },
        {
          instanceLocation => '/{}/my~0tilde~1slash-property',
          keywordLocation => '/$ref/properties/{}/patternProperties/~1/minimum',
          absoluteKeywordLocation => '#/$defs/mydef/properties/%7B%7D/patternProperties/~1/minimum',  # /
          error => 'value is smaller than 6',
        },
        {
          instanceLocation => '/{}/my~0tilde~1slash-property',
          keywordLocation => '/$ref/properties/{}/patternProperties/[~0~1]/minimum',
          absoluteKeywordLocation => '#/$defs/mydef/properties/%7B%7D/patternProperties/%5B~0~1%5D/minimum',  # [~/]
          error => 'value is smaller than 7',
        },
        {
          instanceLocation => '/{}/my~0tilde~1slash-property',
          keywordLocation => '/$ref/properties/{}/patternProperties/~0/minimum',
          absoluteKeywordLocation => '#/$defs/mydef/properties/%7B%7D/patternProperties/~0/minimum',  # ~
          error => 'value is smaller than 5',
        },
        {
          instanceLocation => '/{}/my~0tilde~1slash-property',
          keywordLocation => '/$ref/properties/{}/patternProperties/~0.*~1',
          absoluteKeywordLocation => '#/$defs/mydef/properties/%7B%7D/patternProperties/~0.*~1', # ~.*/
          error => 'property not permitted',
        },
        {
          instanceLocation => '/{}',
          keywordLocation => '/$ref/properties/{}/patternProperties',
          absoluteKeywordLocation => '#/$defs/mydef/properties/%7B%7D/patternProperties',
          error => 'not all properties are valid',
        },
        {
          instanceLocation => '',
          keywordLocation => '/$ref/properties',
          absoluteKeywordLocation => '#/$defs/mydef/properties',
          error => 'not all properties are valid',
        },
      ],
    },
    'JSON pointers are properly escaped; URIs doubly so',
  );

  cmp_deeply(
    evaluate(
      { '{}' => { 'my~tilde/slash-property' => 1 } },
      $schema->{'$defs'}{mydef},
    ),
    {
      valid => false,
      errors => [
        map +{
          error => $_->{error},
          instanceLocation => $_->{instanceLocation},
          keywordLocation => $_->{keywordLocation} =~ s{^/\$ref}{}r,
        }, @$errors
      ],
    },
    'absoluteKeywordLocation is omitted when paths are the same, not counting uri encoding',
  );

  cmp_deeply(
    evaluate(
      { '{}' => { 'my~tilde/slash-property' => 1 } },
      {
        '$defs' => {
          mydef => {
            properties => {
              '{}' => {
                patternProperties => {
                  'a{' => { minimum => 2 }, # this is a broken regex
                },
              },
            },
          },
        },
        '$ref' => '#/$defs/mydef',
      },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => ignore, # not important - JST errors at runtime, JSD2 at traverse time
          keywordLocation => '/$ref/properties/{}/patternProperties/a{',
          absoluteKeywordLocation => '#/$defs/mydef/properties/%7B%7D/patternProperties/a%7B',
          error => re(qr/^Unescaped left brace in regex is (illegal here|deprecated|passed through)/),
        },
      ],
    },
    # all the other _schema_path_suffix cases are tested in the earlier test case
    'use of _schema_path_suffix in a fatal error',
  ) if "$]" >= 5.022;
};

subtest 'invalid $schema' => sub {
  cmp_deeply(
    evaluate(
      1,
      {
        allOf => [
          true,
          { '$schema' => 'https://json-schema.org/draft/2019-09/schema' },
        ],
      },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/allOf/1/$schema',
          error => '$schema can only appear at the schema resource root',
        },
      ],
    },
    '$schema can only appear at the root of a schema, when there is no canonical URI',
  );
};

subtest 'absoluteKeywordLocation' => sub {
  cmp_deeply(
    do {
      local $JSON::Schema::Tiny::MAX_TRAVERSAL_DEPTH = 1;
      evaluate(
        [ [ 1 ] ],
        { items => { '$ref' => '#' } },
      )
    },
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/0',
          keywordLocation => '/items/$ref',
          absoluteKeywordLocation => '',
          error => 'EXCEPTION: maximum evaluation depth exceeded',
        },
      ],
    },
    'absoluteKeywordLocation is included when different from instanceLocation, even when empty',
  );

  cmp_deeply(
    evaluate(1, { '$ref' => '#/does_not_exist' }),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/$ref',
          error => 'EXCEPTION: unable to find resource #/does_not_exist',
        },
      ],
    },
    'absoluteKeywordLocation is not included when the path equals keywordLocation, even if a $ref is present',
  );
};

done_testing;
