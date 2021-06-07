# vim: set ft=perl ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
use 5.016;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use List::Util 1.50 'head';
use Config;
use lib 't/lib';
use Acceptance;

BEGIN {
  my @variables = qw(AUTHOR_TESTING AUTOMATED_TESTING EXTENDED_TESTING);

  plan skip_all => 'These tests may fail if the test suite continues to evolve! They should only be run with '
      .join(', ', map $_.'=1', head(-1, @variables)).' or '.$variables[-1].'=1'
    if not -d '.git' and not grep $ENV{$_}, @variables;
}

acceptance_tests(
  acceptance => {
    skip_dir => 'optional/format',
  },
  output_file => 'draft2019-09.txt',
  test => {
    $ENV{NO_TODO} ? () : ( todo_tests => [
      { file => [ qw(
          anchor.json
          id.json
          recursiveRef.json
          refRemote.json
          unevaluatedItems.json
          unevaluatedProperties.json
        ) ] },
      { file => 'defs.json', group_description => [ 'valid definition', 'validate definition against metaschema' ] },
      { file => 'ref.json', group_description => [
          'remote ref, containing refs itself',
          'Recursive references between schemas',
          'refs with relative uris and defs',
          'relative refs with absolute uris and defs',
        ] },
      { file => 'unknownKeyword.json', group_description => '$id inside an unknown keyword is not a real identifier', test_description => 'type matches second anyOf, which has a real schema in it' },
      { file => [
          'optional/bignum.json',                     # TODO: see JSD2 issue #10
          'optional/ecmascript-regex.json',           # TODO: see JSD2 issue #27
          'optional/float-overflow.json',             # see slack logs re multipleOf algo
        ] },
      # various edge cases that are difficult to accomodate
      $Config{ivsize} < 8 || $Config{nvsize} < 8 ?    # see JSD2 issue #10
        { file => 'const.json',
          group_description => 'float and integers are equal up to 64-bit representation limits',
          test_description => 'float is valid' }
        : (),
      $Config{nvsize} >= 16 ? # see https://github.com/json-schema-org/JSON-Schema-Test-Suite/pull/438#issuecomment-714670854
        { file => 'multipleOf.json',
          group_description => 'invalid instance should not raise error when float division = inf',
          test_description => 'always invalid, but naive implementations may raise an overflow error' }
        : (),
    ] ),
  },
);

done_testing;
__END__

see t/results/draft2019-09.txt for test results
