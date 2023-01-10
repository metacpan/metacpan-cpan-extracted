use strictures 2;
use 5.020;
use experimental qw(signatures postderef);
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use JSON::Schema::Tiny 'evaluate';

use lib 't/lib';
use Helper;

for my $obj (0,1) {
  local $JSON::Schema::Tiny::MAX_TRAVERSAL_DEPTH = 6 if not $obj;

  no warnings 'redefine';
  local *evaluate = sub {
    JSON::Schema::Tiny->new(max_traversal_depth => 6)->evaluate(@_)
  } if $obj;

  cmp_deeply(
    evaluate(
      [ [ [ [ [ 1 ] ] ] ] ],
      {
        items => { '$ref' => '#' },
      },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/0/0/0/0',
          keywordLocation => '/items/$ref/items/$ref/items/$ref/items',
          absoluteKeywordLocation => '#/items',
          error => 'EXCEPTION: maximum evaluation depth exceeded',
        },
      ],
    },
    'evaluation is halted when traversal gets too deep',
  );

  cmp_deeply(
    evaluate(
      1,
      {
        '$defs' => {
          loop_a => {
            '$ref' => '#/$defs/loop_b',
          },
          loop_b => {
            '$ref' => '#/$defs/loop_a',
          },
        },
        '$ref' => '#/$defs/loop_a',
      },
    ),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/$ref/$ref/$ref',
          absoluteKeywordLocation => '#/$defs/loop_a',
          error => 'EXCEPTION: infinite loop detected (same location evaluated twice)',
        },
      ],
    },
    'evaluation is halted when an instance location is evaluated against the same schema location a second time',
  );

  cmp_deeply(
    evaluate(
      { foo => 1 },
      {
        '$defs' => {
          int => { type => 'integer' },
        },
        anyOf => [
          { additionalProperties => { '$ref' => '#/$defs/int' } },
          { additionalProperties => { '$ref' => '#/$defs/int' } },
        ],
      }
    ),
    { valid => true },
    'the seen counter does not confuse two subschemas that both apply the same definition to the same instance location',
  );
}

done_testing;
