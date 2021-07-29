use strict;
use warnings;
use 5.016;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More 0.96;
use Test::Warnings qw(warnings had_no_warnings :no_end_test);
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
};

had_no_warnings() if $ENV{AUTHOR_TESTING};
done_testing;
