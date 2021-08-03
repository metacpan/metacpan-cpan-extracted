use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/JSON/Schema/Draft201909.pm',
    'lib/JSON/Schema/Draft201909/Annotation.pm',
    'lib/JSON/Schema/Draft201909/Document.pm',
    'lib/JSON/Schema/Draft201909/Error.pm',
    'lib/JSON/Schema/Draft201909/Result.pm',
    'lib/JSON/Schema/Draft201909/Utilities.pm',
    'lib/JSON/Schema/Draft201909/Vocabulary.pm',
    'lib/JSON/Schema/Draft201909/Vocabulary/Applicator.pm',
    'lib/JSON/Schema/Draft201909/Vocabulary/Content.pm',
    'lib/JSON/Schema/Draft201909/Vocabulary/Core.pm',
    'lib/JSON/Schema/Draft201909/Vocabulary/Format.pm',
    'lib/JSON/Schema/Draft201909/Vocabulary/MetaData.pm',
    'lib/JSON/Schema/Draft201909/Vocabulary/Validation.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/additional-tests-draft2019-09.t',
    't/additional-tests-draft2019-09/README',
    't/additional-tests-draft2019-09/anchor.json',
    't/additional-tests-draft2019-09/badRef.json',
    't/additional-tests-draft2019-09/faux-buggy-schemas.json',
    't/additional-tests-draft2019-09/format-duration.json',
    't/additional-tests-draft2019-09/format-ipv4.json',
    't/additional-tests-draft2019-09/format-relative-json-pointer.json',
    't/additional-tests-draft2019-09/format-time.json',
    't/additional-tests-draft2019-09/future-keywords-draft2019-09.json',
    't/additional-tests-draft2019-09/id.json',
    't/additional-tests-draft2019-09/keyword-independence.json',
    't/additional-tests-draft2019-09/loose-types-const-enum.json',
    't/additional-tests-draft2019-09/recursive-dynamic.json',
    't/additional-tests-draft2019-09/ref-and-id.json',
    't/additional-tests-draft2019-09/ref.json',
    't/additional-tests-draft2019-09/short-circuit.json',
    't/additional-tests-draft2019-09/unicode.json',
    't/additional-tests-draft2019-09/vocabulary.json',
    't/invalid-schemas-draft2019-09.t',
    't/invalid-schemas-draft2019-09/invalid-input.json',
    't/invalid-schemas-draft2019-09/ref.json',
    't/lib/Acceptance.pm',
    't/lib/Helper.pm',
    't/results/draft2019-09-acceptance-format.txt',
    't/results/draft2019-09-acceptance.txt',
    't/results/draft2019-09-additional-tests.txt',
    't/results/draft2019-09-invalid-schemas.txt',
    't/unsupported-keywords.t',
    't/zzz-acceptance-draft2019-09-format.t',
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

notabs_ok($_) foreach @files;
done_testing;
