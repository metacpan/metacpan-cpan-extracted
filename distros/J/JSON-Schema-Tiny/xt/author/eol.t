use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/JSON/Schema/Tiny.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/additional-tests-draft2019-09.t',
    't/additional-tests-draft2019-09/README',
    't/additional-tests-draft2019-09/id.json',
    't/additional-tests-draft2019-09/invalid-input.json',
    't/additional-tests-draft2019-09/keyword-independence.json',
    't/additional-tests-draft2019-09/loose-types-const-enum.json',
    't/additional-tests-draft2019-09/ref-and-id.json',
    't/additional-tests-draft2019-09/ref.json',
    't/additional-tests-draft2019-09/short-circuit.json',
    't/additional-tests-draft2019-09/unicode.json',
    't/additional-tests-draft2019-09/vocabulary.json',
    't/boolean-data.t',
    't/boolean-schemas.t',
    't/equality.t',
    't/errors.t',
    't/lib/Acceptance.pm',
    't/lib/Helper.pm',
    't/max_traversal_depth.t',
    't/pattern.t',
    't/ref.t',
    't/results/draft2019-09-additional-tests.txt',
    't/results/draft2019-09.txt',
    't/type.t',
    't/unsupported-keywords.t',
    't/zzz-acceptance-draft2019-09.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
