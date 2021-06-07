# vim: set ft=perl ts=8 sts=2 sw=2 tw=100 et :
use strict;
use warnings;
use 5.016;
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use lib 't/lib';
use Acceptance;
use Path::Tiny;
use JSON::MaybeXS;

my $version = 'draft2019-09';

acceptance_tests(
  acceptance => {
    include_optional => 0,
    test_dir =>'t/additional-tests-'.$version,
  },
  output_file => $version.'-additional-tests.txt',
  test => {
    $ENV{NO_TODO} ? () : ( todo_tests => [
      { file => 'keyword-independence.json', group_description => [
        grep /unevaluated/,
        map $_->{description},
        @{ decode_json(path('t/additional-tests-'.$version.'/keyword-independence.json')->slurp_raw) }
      ] },
    ] ),
  },
);

done_testing;
