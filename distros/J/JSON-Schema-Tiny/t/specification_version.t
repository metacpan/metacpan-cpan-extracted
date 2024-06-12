# vim: set ft=perl ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More 0.96;
use Test::Warnings qw(warnings :no_end_test had_no_warnings);
use Test::Fatal;
use Test::Deep;
use JSON::Schema::Tiny 'evaluate';
use lib 't/lib';
use Helper;

{
  local $JSON::Schema::Tiny::SPECIFICATION_VERSION = 'ohhai';
  like(
    exception { ()= evaluate(true, true) },
    qr/^\$SPECIFICATION_VERSION value is invalid/,
    'unrecognized $SPECIFICATION_VERSION',
  );
}

+subtest '$schema' => sub {
  cmp_deeply(
    evaluate(
      true,
      { '$schema' => 'http://wrong/url' },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/$schema',
          error => re(qr/^custom \$schema URIs are not supported \(must be one of: /),
        },
      ],
    },
    '$schema, when set, must contain a recognizable URI',
  );

  local $JSON::Schema::Tiny::SPECIFICATION_VERSION = 'draft2020-12';
  cmp_deeply(
    evaluate(
      true,
      {
        '$schema' => 'https://json-schema.org/draft/2019-09/schema',
      },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/$schema',
          error => '"$schema" indicates a different version than that requested by $JSON::Schema::Tiny::SPECIFICATION_VERSION',
        },
      ],
    },
    '$SPECIFICATION_VERSION cannot be inconsistent with $schema keyword value',
  );
};

subtest 'specification aliases' => sub {
  local $JSON::Schema::Tiny::SPECIFICATION_VERSION = '2020-12';
  ok(evaluate(1, {}), 'evaluate with 2020-12');
  is(
    $JSON::Schema::Tiny::SPECIFICATION_VERSION,
    'draft2020-12',
    '2020-12 is accepted as an alias for draft2020-12',
  );

  local $JSON::Schema::Tiny::SPECIFICATION_VERSION = '2019-09';
  ok(evaluate(1, {}), 'evaluate with 2019-09');
  is(
    $JSON::Schema::Tiny::SPECIFICATION_VERSION,
    'draft2019-09',
    '2019-09 is accepted as an alias for draft2019-09',
  );

  local $JSON::Schema::Tiny::SPECIFICATION_VERSION = '7';
  ok(evaluate(1, {}), 'evaluate with 7');
  is(
    $JSON::Schema::Tiny::SPECIFICATION_VERSION,
    'draft7',
    '7 is accepted as an alias for draft7',
  );
};

subtest '$ref and older specification versions' => sub {
  cmp_deeply(
    evaluate(
      true,
      {
        '$schema' => 'http://json-schema.org/draft-07/schema#',
        '$ref' => '#/definitions/foo',
      },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/$schema',
          error => '$schema and $ref cannot be used together in older drafts',
        },
      ],
    },
    '$schema and $ref cannot be used together, when $schema is too old',
  );
};

subtest '<= draft7: $ref in combination with any other keyword causes the other keywords to be ignored' => sub {
  local $JSON::Schema::Tiny::SPECIFICATION_VERSION = 'draft7';
  cmp_deeply(
    evaluate(
      1,
      {
        allOf => [
          true,
          {
            '$ref' => '#/allOf/0',
            maximum => 0,
          },
        ],
      }
    ),
    {
      valid => true,
    },
    'keywords adjacent to $ref are not evaluated',
  );
};

subtest '$ref adjacent to a path used in a $ref' => sub {
  local $JSON::Schema::Tiny::SPECIFICATION_VERSION = 'draft7';
  local $TODO = 'fixing this requires traversing the schema to mark which locations are unusable';
  cmp_deeply(
    evaluate(
      true,
      {
        allOf => [
          true,
          {
            anyOf => [ false, true ],
            '$ref' => '#/allOf/0',
          },
          {
            # a reference that cannot be resolved
            '$ref' => '#/allOf/1/anyOf/1',
          },
        ],
      },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/allOf/$ref',
          error => 'EXCEPTION: unable to find resource #/definitions/bar/anyOf/1',
        },
      ],
    },
    'the presence of $ref also kills the use of other $refs to adjacent locations',
  );
};

subtest '$defs support' => sub {
  local $JSON::Schema::Tiny::SPECIFICATION_VERSION = 'draft7';
  cmp_deeply(
    evaluate(
      1,
      my $schema = {
        '$defs' => 1,
        allOf => [ { '$ref' => '#/$defs/foo' } ],
      }
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/allOf/0/$ref',
          error => 'EXCEPTION: unable to find resource #/$defs/foo',
        },
      ],
    },
    '$defs is not recognized in <= draft7',
  );

  local $JSON::Schema::Tiny::SPECIFICATION_VERSION = 'draft2019-09';
  cmp_deeply(
    evaluate(1, $schema),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/$defs',
          error => '$defs value is not an object',
        },
      ],
    },
    '$defs is supported in > draft7',
  );
};

subtest 'definitions support' => sub {
  local $JSON::Schema::Tiny::SPECIFICATION_VERSION = 'draft2019-09';
  cmp_deeply(
    evaluate(
      1,
      my $schema = {
        definitions => 1,
        allOf => [ { '$ref' => '#/definitions/foo' } ],
      }
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/allOf/0/$ref',
          error => 'EXCEPTION: unable to find resource #/definitions/foo',
        },
      ],
    },
    'definitions is not recognized in >= draft2019-09',
  );

  local $JSON::Schema::Tiny::SPECIFICATION_VERSION = 'draft7';
  cmp_deeply(
    evaluate(1, $schema),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/definitions',
          error => 'definitions value is not an object',
        },
      ],
    },
    'definitions is supported in <= draft7',
  );
};

subtest 'dependencies, dependentRequired, dependentSchemas' => sub {
  local $JSON::Schema::Tiny::SPECIFICATION_VERSION = 'draft2019-09';
  my $dependencies_schema;
  my @warnings = warnings {
    cmp_deeply(
      evaluate(
        { alpha => 1, beta => 2 },
        $dependencies_schema = {
          dependencies => {
            alpha => [ qw(a b c) ],
            beta => false,
          },
        }
      ),
      { valid => true },
      'dependencies is not recognized in >= draft2019-09',
    );
  };
  cmp_deeply(
    \@warnings,
    [ re(qr/^no-longer-supported "dependencies" keyword present/) ],
    'warned when using no-longer-supported keyword',
  );

  cmp_deeply(
    evaluate(
      { alpha => 1, beta => 2 },
      my $dependentRequired_schema = {
        dependentRequired => {
          alpha => [ qw(a b c) ],
        },
      },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/dependentRequired/alpha',
          error => 'missing properties: a, b, c',
        },
        {
          instanceLocation => '',
          keywordLocation => '/dependentRequired',
          error => 'not all dependencies are satisfied',
        },
      ],
    },
    'dependentRequired is supported in >= draft2019-09',
  );

  cmp_deeply(
    evaluate(
      { alpha => 1, beta => 2 },
      my $dependentSchemas_schema = {
        dependentSchemas => {
          beta => false,
        },
      },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/dependentSchemas/beta',
          error => 'subschema is false',
        },
        {
          instanceLocation => '',
          keywordLocation => '/dependentSchemas',
          error => 'not all dependencies are satisfied',
        },
      ],
    },
    'dependentSchemas is supported in >= draft2019-09',
  );

  local $JSON::Schema::Tiny::SPECIFICATION_VERSION = 'draft7';
  cmp_deeply(
    evaluate(
      { alpha => 1, beta => 2 },
      $dependencies_schema,
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/dependencies/alpha',
          error => 'missing properties: a, b, c',
        },
        {
          instanceLocation => '',
          keywordLocation => '/dependencies/beta',
          error => 'subschema is false',
        },
        {
          instanceLocation => '',
          keywordLocation => '/dependencies',
          error => 'not all dependencies are satisfied',
        },
      ],
    },
    'dependencies is supported in <= draft7',
  );

  cmp_deeply(
    evaluate(
      { alpha => 1, beta => 2 },
      $dependentRequired_schema,
    ),
    { valid => true },
    'dependentRequired is not recognized in <= draft7',
  );

  cmp_deeply(
    evaluate(
      { alpha => 1, beta => 2 },
      $dependentSchemas_schema,
    ),
    { valid => true },
    'dependentSchemas is not recognized in <= draft7',
  );
};

subtest 'prefixItems, items and additionalItems' => sub {
  local $JSON::Schema::Tiny::SPECIFICATION_VERSION = 'draft2020-12';
  cmp_deeply(
    evaluate(
      [ 1, 2 ],
      {
        prefixItems => [ { maximum => 0 } ],
        items => { maximum => 1 },
      }
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/0',
          keywordLocation => '/prefixItems/0/maximum',
          error => 'value is larger than 0',
        },
        {
          instanceLocation => '',
          keywordLocation => '/prefixItems',
          error => 'not all items are valid',
        },
        {
          instanceLocation => '/1',
          keywordLocation => '/items/maximum',
          error => 'value is larger than 1',
        },
        {
          instanceLocation => '',
          keywordLocation => '/items',
          error => 'subschema is not valid against all additional items',
        },
      ],
    },
    'prefixItems+items works when $SPECIFICATION_VERSION is set to draft2020-12',
  );

  cmp_deeply(
    evaluate(
      [ 1 ],
      {
        items => [ { maximum => 0 } ],
      },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/items',
          error => 'array form of "items" not supported in draft2020-12',
        },
      ],
    },
    'array form of items not supported when $SPECIFICATION_VERSION specifies draft2020-12',
  );

  my @warnings = warnings {
    cmp_deeply(
      evaluate(
        [ 1 ],
        { additionalItems => false },
      ),
      { valid => true },
      'additionalItems not recognized when $SPECIFICATION_VERSION specifies draft2020-12',
    );
  };
  cmp_deeply(
    \@warnings,
    [ re(qr/^no-longer-supported "additionalItems" keyword present/) ],
    'warned when using no-longer-supported keyword',
  );

  local $JSON::Schema::Tiny::SPECIFICATION_VERSION = 'draft2019-09';
  cmp_deeply(
    evaluate(
      [ 1 ],
      { prefixItems => [ { maximum => 0 } ] }
    ),
    { valid => true },
    'prefixItems not supported when $SPECIFICATION_VERSION specifies other than draft2020-12',
  );

  local $JSON::Schema::Tiny::SPECIFICATION_VERSION;
  cmp_deeply(
    evaluate(
      [ 1, 2, 3 ],
      {
        prefixItems => [ { maximum => 0 } ],
        items => [ { maximum => 1 } ],
      },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/0',
          keywordLocation => '/prefixItems/0/maximum',
          error => 'value is larger than 0',
        },
        {
          instanceLocation => '',
          keywordLocation => '/prefixItems',
          error => 'not all items are valid',
        },
      ],
    },
    'prefixItems + array-based items',
  );

  cmp_deeply(
    evaluate(
      [ 1, 2, 3 ],
      {
        prefixItems => [ { maximum => 0 } ],
        additionalItems => { maximum => 1 },
      },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/0',
          keywordLocation => '/prefixItems/0/maximum',
          error => 'value is larger than 0',
        },
        {
          instanceLocation => '',
          keywordLocation => '/prefixItems',
          error => 'not all items are valid',
        },
        {
          instanceLocation => '/1',
          keywordLocation => '/additionalItems/maximum',
          error => 'value is larger than 1',
        },
        {
          instanceLocation => '/2',
          keywordLocation => '/additionalItems/maximum',
          error => 'value is larger than 1',
        },
        {
          instanceLocation => '',
          keywordLocation => '/additionalItems',
          error => 'subschema is not valid against all additional items',
        },
      ],
    },
    'prefixItems + additionalItems',
  );

  cmp_deeply(
    evaluate(
      [ 1, 2, 3 ],
      {
        prefixItems => [ { maximum => 0 } ],
        items => { maximum => 1 },
      }
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/0',
          keywordLocation => '/prefixItems/0/maximum',
          error => 'value is larger than 0',
        },
        {
          instanceLocation => '',
          keywordLocation => '/prefixItems',
          error => 'not all items are valid',
        },
        {
          instanceLocation => '/1',
          keywordLocation => '/items/maximum',
          error => 'value is larger than 1',
        },
        {
          instanceLocation => '/2',
          keywordLocation => '/items/maximum',
          error => 'value is larger than 1',
        },
        {
          instanceLocation => '',
          keywordLocation => '/items',
          error => 'subschema is not valid against all additional items',
        },
      ],
    },
    'prefixItems + schema-based items',
  );

  cmp_deeply(
    evaluate(
      [ 1, 2, 3 ],
      {
        items => { maximum => 0 },
        additionalItems => { maximum => 1 },
      }
    ),
    {
      valid => false,
      errors => [
        (map +{
          instanceLocation => '/'.$_,
          keywordLocation => '/items/maximum',
          error => 'value is larger than 0',
        }, (0..2)),
        {
          instanceLocation => '',
          keywordLocation => '/items',
          error => 'subschema is not valid against all items',
        },
      ],
    },
    'schema-based items + additionalItems, failure case',
  );

  cmp_deeply(
    evaluate(
      [ 1, 2, 3 ],
      {
        items => { maximum => 5 },
        additionalItems => { maximum => 0 },
      }
    ),
    { valid => true },
    'schema-based items + additionalItems, passing case',
  );
};

subtest '$id' => sub {
  my $schema = { '$id' => '#/foo/bar/baz' };
  foreach my $version (qw(draft2020-12 draft2019-09 draft7)) {
    local $JSON::Schema::Tiny::SPECIFICATION_VERSION = $version;
    cmp_deeply(
      evaluate(1, $schema),
      {
        valid => false,
        errors => [
          {
            instanceLocation => '',
            keywordLocation => '/$id',
            error => ($version eq 'draft7'
              ? '$id value does not match required syntax'
              : '$id value "#/foo/bar/baz" cannot have a non-empty fragment'),
          },
        ],
      },
      'json pointer fragment is valid in $id in '.$version,
    );
  }
};

had_no_warnings() if $ENV{AUTHOR_TESTING};
done_testing;
