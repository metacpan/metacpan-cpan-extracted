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

foreach my $keyword (
    # CORE KEYWORDS
    qw($id $anchor $recursiveAnchor $recursiveRef $vocabulary $dynamicAnchor $dynamicRef definitions),
    # APPLICATOR KEYWORDS
    qw(dependencies unevaluatedItems unevaluatedProperties),
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

done_testing;
