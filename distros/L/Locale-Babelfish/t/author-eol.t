
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Locale/Babelfish.pm',
    'lib/Locale/Babelfish/Phrase/Compiler.pm',
    'lib/Locale/Babelfish/Phrase/Literal.pm',
    'lib/Locale/Babelfish/Phrase/Node.pm',
    'lib/Locale/Babelfish/Phrase/Parser.pm',
    'lib/Locale/Babelfish/Phrase/ParserBase.pm',
    'lib/Locale/Babelfish/Phrase/PluralForms.pm',
    'lib/Locale/Babelfish/Phrase/PluralFormsParser.pm',
    'lib/Locale/Babelfish/Phrase/Pluralizer.pm',
    'lib/Locale/Babelfish/Phrase/Variable.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Phrase/Compiler.t',
    't/Phrase/Node.t',
    't/Phrase/Parser.t',
    't/Phrase/PluralFormsParser.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/l10n2.t',
    't/locales/sub/sub1/sub3/test.en_US.yaml',
    't/locales/sub/sub1/sub3/test.ru_RU.yaml',
    't/locales/sub/sub2/sub3/test.en_US.yaml',
    't/locales/sub/sub2/sub3/test.ru_RU.yaml',
    't/locales/sub/test.en_US.yaml',
    't/locales/sub/test.ru_RU.yaml',
    't/locales/test.en_US.yaml',
    't/locales/test.ru_RU.yaml',
    't/release-distmeta.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
