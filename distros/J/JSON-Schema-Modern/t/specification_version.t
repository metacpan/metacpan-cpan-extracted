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
no if "$]" >= 5.041009, feature => 'smartmatch';
no feature 'switch';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::Warnings qw(warnings :no_end_test had_no_warnings);
use Test::Fatal;
use lib 't/lib';
use Helper;

{
  like(
    exception { ()= JSON::Schema::Modern->new(specification_version => 'ohhai')->evaluate(true, true) },
    qr/^Value "ohhai" did not pass type constraint/,
    'unrecognized $SPECIFICATION_VERSION',
  );
}

subtest 'specification aliases' => sub {
  is(
    JSON::Schema::Modern->new(specification_version => '2020-12')->specification_version,
    'draft2020-12',
    '2020-12 is an alias for draft2020-12',
  );

  is(
    JSON::Schema::Modern->new(specification_version => '2019-09')->specification_version,
    'draft2019-09',
    '2019-09 is an alias for draft2019-09',
  );

  is(
    JSON::Schema::Modern->new(specification_version => '7')->specification_version,
    'draft7',
    '7 is an alias for draft7',
  );
};

subtest '$ref and older specification versions' => sub {
  cmp_result(
    JSON::Schema::Modern->new->evaluate(
      true,
      {
        '$schema' => 'http://json-schema.org/draft-07/schema#',
        '$ref' => '#/definitions/foo',
      }
    )->TO_JSON,
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
  cmp_result(
    JSON::Schema::Modern->new(
      specification_version => 'draft7',
    )->evaluate(
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
    )->TO_JSON,
    { valid => true },
    'keywords adjacent to $ref are not evaluated',
  );
};

subtest '$ref adjacent to a path used in a $ref' => sub {
  cmp_result(
    JSON::Schema::Modern->new(specification_version => 'draft7')->evaluate(
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
    )->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/allOf/2/$ref',
          error => 'EXCEPTION: bad reference to "#/allOf/1/anyOf/1": not a schema',
        },
      ],
    },
    'the presence of $ref also blocks the use of other $refs to adjacent locations',
  );
};

subtest '$defs support' => sub {
  cmp_result(
    JSON::Schema::Modern->new(specification_version => 'draft7')->evaluate(
      1,
      my $schema = {
        '$defs' => 1,
        allOf => [ { '$ref' => '#/$defs/foo' } ],
      }
    )->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/allOf/0/$ref',
          error => 'EXCEPTION: unable to find resource "#/$defs/foo"',
        },
      ],
    },
    '$defs is not recognized in <= draft7',
  );

  cmp_result(
    JSON::Schema::Modern->new(specification_version => 'draft2019-09')->evaluate(1, $schema)->TO_JSON,
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
  my $schema;
  my @warnings = warnings {
    cmp_result(
      JSON::Schema::Modern->new(specification_version => 'draft2019-09')->evaluate(
        1,
        $schema = {
          definitions => 1,
          allOf => [ { '$ref' => '#/definitions/foo' } ],
        }
      )->TO_JSON,
      {
        valid => false,
        errors => [
          {
            instanceLocation => '',
            keywordLocation => '/allOf/0/$ref',
            error => 'EXCEPTION: unable to find resource "#/definitions/foo"',
          },
        ],
      },
      'definitions is not recognized in >= draft2019-09',
    );
  };
  cmp_result(
    \@warnings,
    [ re(qr/^no-longer-supported "definitions" keyword present/) ],
    'warned when using no-longer-supported keyword',
  );

  cmp_result(
    JSON::Schema::Modern->new(specification_version => 'draft7')->evaluate(1, $schema)->TO_JSON,
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
  my $js = JSON::Schema::Modern->new(specification_version => 'draft2019-09');
  my $dependencies_schema;
  my @warnings = warnings {
    cmp_result(
      $js->evaluate(
        { alpha => 1, beta => 2 },
        $dependencies_schema = {
          dependencies => {
            alpha => [ qw(a b c) ],
            beta => false,
          },
        }
      )->TO_JSON,
      { valid => true },
      'dependencies is not recognized in >= draft2019-09',
    );
  };
  cmp_result(
    \@warnings,
    [ re(qr/^no-longer-supported "dependencies" keyword present/) ],
    'warned when using no-longer-supported keyword',
  );

  cmp_result(
    $js->evaluate(
      { alpha => 1, beta => 2 },
      my $dependentRequired_schema = {
        dependentRequired => {
          alpha => [ qw(a b c) ],
        },
      },
    )->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/dependentRequired/alpha',
          error => 'object is missing properties: a, b, c',
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

  cmp_result(
    $js->evaluate(
      { alpha => 1, beta => 2 },
      my $dependentSchemas_schema = {
        dependentSchemas => {
          beta => false,
        },
      },
    )->TO_JSON,
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

  $js = JSON::Schema::Modern->new(specification_version => 'draft7');
  cmp_result(
    $js->evaluate(
      { alpha => 1, beta => 2 },
      $dependencies_schema,
    )->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/dependencies/alpha',
          error => 'object is missing properties: a, b, c',
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

  cmp_result(
    $js->evaluate(
      { alpha => 1, beta => 2 },
      $dependentRequired_schema,
    )->TO_JSON,
    { valid => true },
    'dependentRequired is not recognized in <= draft7',
  );

  cmp_result(
    $js->evaluate(
      { alpha => 1, beta => 2 },
      $dependentSchemas_schema,
    )->TO_JSON,
    { valid => true },
    'dependentSchemas is not recognized in <= draft7',
  );
};

subtest 'prefixItems, items and additionalItems' => sub {
  my $js = JSON::Schema::Modern->new;
  cmp_result(
    $js->evaluate(
      [ 1, 2 ],
      {
        prefixItems => [ { maximum => 0 } ],
        items => { maximum => 1 },
      }
    )->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/0',
          keywordLocation => '/prefixItems/0/maximum',
          error => 'value is greater than 0',
        },
        {
          instanceLocation => '',
          keywordLocation => '/prefixItems',
          error => 'not all items are valid',
        },
        {
          instanceLocation => '/1',
          keywordLocation => '/items/maximum',
          error => 'value is greater than 1',
        },
        {
          instanceLocation => '',
          keywordLocation => '/items',
          error => 'subschema is not valid against all items',
        },
      ],
    },
    'prefixitems+items works when specification_version >= draft2020-12',
  );

  cmp_result(
    $js->evaluate(
      [ 1 ],
      {
        items => [ { maximum => 0 } ],
      },
    )->TO_JSON,
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
    'array form of items not supported when specification_version >= draft2020-12',
  );

  my @warnings = warnings {
    cmp_result(
      $js->evaluate(
        [ 1 ],
        { additionalItems => false },
      )->TO_JSON,
      { valid => true },
      'additionalitems not recognized when specification_version >= draft2020-12',
    );
  };
  cmp_result(
    \@warnings,
    [ re(qr/^no-longer-supported "additionalItems" keyword present/) ],
    'warned when using no-longer-supported keyword',
  );

  cmp_result(
    JSON::Schema::Modern->new(specification_version => 'draft2019-09')->evaluate(
      [ 1 ],
      { prefixItems => [ { maximum => 0 } ] }
    )->TO_JSON,
    { valid => true },
    'prefixitems not supported when specification_version specifies other than draft2020-12',
  );

  cmp_result(
    $js->evaluate(
      [ 1, 2, 3 ],
      {
        prefixItems => [ { maximum => 0 } ],
        items => [ { maximum => 1 } ],
      },
    )->TO_JSON,
    {
      valid => false,
      errors => [
        {
          error => "array form of \"items\" not supported in draft2020-12",
          instanceLocation => '',
          keywordLocation => '/items',
        },
      ],
    },
    'array-based items in >= draft2020-12',
  );

  @warnings = warnings {
    cmp_result(
      $js->evaluate(
        [ 1, 2, 3 ],
        {
          prefixItems => [ { maximum => 0 } ],
          additionalItems => { maximum => 1 },
        },
      )->TO_JSON,
      {
        valid => false,
        errors => [
          {
            instanceLocation => '/0',
            keywordLocation => '/prefixItems/0/maximum',
            error => 'value is greater than 0',
          },
          {
            instanceLocation => '',
            keywordLocation => '/prefixItems',
            error => 'not all items are valid',
          },
        ],
      },
      'prefixItems + additionalItems',
    );
  };
  cmp_result(
    \@warnings,
    [ re(qr/^no-longer-supported "additionalItems" keyword present/) ],
    'warned when using no-longer-supported keyword',
  );

  cmp_result(
    $js->evaluate(
      [ 1, 2, 3 ],
      {
        prefixItems => [ { maximum => 0 } ],
        items => { maximum => 1 },
      }
    )->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/0',
          keywordLocation => '/prefixItems/0/maximum',
          error => 'value is greater than 0',
        },
        {
          instanceLocation => '',
          keywordLocation => '/prefixItems',
          error => 'not all items are valid',
        },
        {
          instanceLocation => '/1',
          keywordLocation => '/items/maximum',
          error => 'value is greater than 1',
        },
        {
          instanceLocation => '/2',
          keywordLocation => '/items/maximum',
          error => 'value is greater than 1',
        },
        {
          instanceLocation => '',
          keywordLocation => '/items',
          error => 'subschema is not valid against all items',
        },
      ],
    },
    'prefixItems + schema-based items',
  );

  @warnings = warnings {
    cmp_result(
      $js->evaluate(
        [ 1, 2, 3 ],
        {
          items => { maximum => 0 },
          additionalItems => { maximum => 1 },
        }
      )->TO_JSON,
      {
        valid => false,
        errors => [
          (map +{
            instanceLocation => '/'.$_,
            keywordLocation => '/items/maximum',
            error => 'value is greater than 0',
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
  };
  cmp_result(
    \@warnings,
    [ re(qr/^no-longer-supported "additionalItems" keyword present/) ],
    'warned when using no-longer-supported keyword',
  );

  @warnings = warnings {
    cmp_result(
      $js->evaluate(
        [ 1, 2, 3 ],
        {
          items => { maximum => 5 },
          additionalItems => { maximum => 0 },
        }
      )->TO_JSON,
      { valid => true },
      'schema-based items + additionalItems, passing case',
    );
  };
  cmp_result(
    \@warnings,
    [ re(qr/^no-longer-supported "additionalItems" keyword present/) ],
    'warned when using no-longer-supported keyword',
  );
};

had_no_warnings() if $ENV{AUTHOR_TESTING};
done_testing;
