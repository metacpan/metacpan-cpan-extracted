use strict;
use warnings;
use 5.016;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More 0.96;
use Test::Warnings 'warnings';
use Test::Deep;
use JSON::Schema::Tiny 'evaluate';
use lib 't/lib';
use Helper;

foreach my $keyword (
    # APPLICATOR KEYWORDS
    qw(unevaluatedItems unevaluatedProperties),
) {
  cmp_deeply(
    evaluate(true, { $keyword => 1 }),
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/'.$keyword,
          error => 'keyword not supported',
        },
      ],
    },
    'use of "'.$keyword.'" results in error',
  );
}

my %warnings = (
  definitions => qr/^no-longer-supported "definitions" keyword present \(at location ""\): this should be rewritten as "\$defs" at /,
  dependencies => qr/^no-longer-supported "dependencies" keyword present \(at location ""\): this should be rewritten as "dependentSchemas" or "dependentRequired" at /,
);

foreach my $keyword (keys %warnings) {
  cmp_deeply(
    [ warnings { ok(evaluate(true, { $keyword => 1 }), 'schema with '.$keyword.' still validates') } ],
    [ re($warnings{$keyword}), ],
    'warned for '.$keyword,
  );
}

done_testing;
