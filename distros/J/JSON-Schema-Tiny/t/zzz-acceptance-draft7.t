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

use Test::More;
use List::Util 1.50 'head';
use Config;
use lib 't/lib';
use Acceptance;

BEGIN {
  my @variables = qw(AUTHOR_TESTING AUTOMATED_TESTING EXTENDED_TESTING);

  plan skip_all => 'These tests may fail if the test suite continues to evolve! They should only be run with '
      .join(', ', map $_.'=1', head(-1, @variables)).' or '.$variables[-1].'=1'
    if not grep $ENV{$_}, @variables;
}

my $version = 'draft7';

acceptance_tests(
  acceptance => {
    specification => $version,
    skip_dir => 'optional/format',
  },
  evaluator => {
    specification_version => $version,
  },
  output_file => $version.'-acceptance.txt',
  test => {
    $ENV{NO_TODO} ? () : ( todo_tests => [
      # unsupported keywords or subfeatures
      { file => [ qw(
          id.json
          refRemote.json
          vocabulary.json
          optional/content.json
        ) ] },
      { file => 'definitions.json', group_description => [ 'valid definition', 'validate definition against metaschema' ] },
      # various edge cases that are difficult to accomodate
      $Config{ivsize} < 8 ? { file => 'multipleOf.json', group_description => 'small multiple of large integer', test_description => 'any integer is a multiple of 1e-8' } : (),

      # only same-document, same-base JSON pointers are supported in $ref
      { file => 'ref.json', group_description => [
          '$ref prevents a sibling $id from changing the base uri',
          'remote ref, containing refs itself',
          'Recursive references between schemas',
          'Location-independent identifier',
          'Reference an anchor with a non-relative URI',
          'Location-independent identifier with base URI change in subschema',
          'refs with relative uris and defs',
          'relative refs with absolute uris and defs',
          '$id must be resolved against nearest parent, not just immediate parent',
          'URN base URI with URN and anchor ref',
          'ref to if',
          'ref to then',
          'ref to else',
          'ref with absolute-path-reference',
        ] },
      { file => ['unknownKeyword.json', 'optional/unknownKeyword.json'], group_description => '$id inside an unknown keyword is not a real identifier', test_description => 'type matches second anyOf, which has a real schema in it' },
      { file => 'optional/id.json', '$id inside an enum is not a real identifier', 'exact match to enum, and type matches' },
      { file => 'optional/cross-draft.json', group_description => 'refs to future drafts are processed as future drafts' },
      # various edge cases that are difficult to accomodate
      { file => 'optional/ecmascript-regex.json', group_description => '\w in patterns matches [A-Za-z0-9_], not unicode letters', test_description => [ 'literal unicode character in json string', 'unicode character in hex format in string' ] },
      { file => 'optional/ecmascript-regex.json', group_description => '\d in pattern matches [0-9], not unicode digits', test_description => 'non-ascii digits (BENGALI DIGIT FOUR, BENGALI DIGIT TWO)' },
      { file => 'optional/ecmascript-regex.json', group_description => '\w in patternProperties matches [A-Za-z0-9_], not unicode letters', test_description => [ 'literal unicode character in json string', 'unicode character in hex format in string' ] },
      { file => 'optional/ecmascript-regex.json', group_description => '\d in patternProperties matches [0-9], not unicode digits', test_description => 'non-ascii digits (BENGALI DIGIT FOUR, BENGALI DIGIT TWO)' },
      { file => 'optional/ecmascript-regex.json', group_description => [ 'ECMA 262 \d matches ascii digits only', 'ECMA 262 \D matches everything but ascii digits', 'ECMA 262 \w matches ascii letters only', 'ECMA 262 \W matches everything but ascii letters' ] }, # TODO, see test suite PR#505
      { file => 'optional/ecmascript-regex.json', group_description => 'ECMA 262 \s matches whitespace', test_description => 'zero-width whitespace matches' },
      { file => 'optional/ecmascript-regex.json', group_description => 'ECMA 262 \S matches everything but whitespace', test_description => 'zero-width whitespace does not match' },
      "$]" < 5.017001 ? ( # in Unicode 6.2, vertical tab was added to \s
        { file => 'optional/ecmascript-regex.json', group_description => 'ECMA 262 \s matches whitespace', test_description => 'Line tabulation matches' },
        { file => 'optional/ecmascript-regex.json', group_description => 'ECMA 262 \S matches everything but whitespace', test_description => 'Line tabulation does not match' },
      ) : (),
    ] ),
  },
);

END {
diag <<DIAG

###############################

Attention CPANTesters: you do not need to file a ticket when this test fails. I will receive the test reports and act on it soon. thank you!

###############################
DIAG
  if not Test::Builder->new->is_passing;
}

done_testing;
__END__
see t/results/draft7-acceptance.txt for test results
