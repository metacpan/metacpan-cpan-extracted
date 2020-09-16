use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/JSON/Schema/Draft201909.pm',
    'lib/JSON/Schema/Draft201909/Annotation.pm',
    'lib/JSON/Schema/Draft201909/Document.pm',
    'lib/JSON/Schema/Draft201909/Error.pm',
    'lib/JSON/Schema/Draft201909/Result.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/add-schema.t',
    't/additional-tests.t',
    't/additional-tests/README',
    't/additional-tests/anchor.json',
    't/additional-tests/format-duration.json',
    't/additional-tests/future-keywords-draft2019-09.json',
    't/additional-tests/id.json',
    't/additional-tests/invalid-id-and-anchor.json',
    't/additional-tests/keyword-independence.json',
    't/additional-tests/not-an-anchor.json',
    't/additional-tests/not-an-id.json',
    't/additional-tests/recursiveRef.json',
    't/additional-tests/ref-and-id.json',
    't/additional-tests/ref.json',
    't/additional-tests/short-circuit.json',
    't/additional-tests/unicode.json',
    't/annotations.t',
    't/booleans.t',
    't/cached-metaschemas.t',
    't/document.t',
    't/equality.t',
    't/errors.t',
    't/evaluate_json_string.t',
    't/find-identifiers.t',
    't/formats.t',
    't/lib/Helper.pm',
    't/max_traversal_depth.t',
    't/output_format.t',
    't/pattern.t',
    't/ref.t',
    't/type.t',
    't/zzz-acceptance.t',
    'xt/author/00-compile.t',
    'xt/author/changes_has_content.t',
    'xt/author/clean-namespaces.t',
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
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
