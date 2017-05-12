use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Locale/Maketext/Test.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/locale_checkauto.t',
    't/locale_checkwarnings.t',
    't/locale_invalidlocale.t',
    't/locale_nopofiles.t',
    't/locale_notranslations.t',
    't/locale_validlocale.t',
    't/locales/id.po',
    't/locales/pt.po',
    't/locales/ru.po',
    't/rc/.perlcriticrc',
    't/rc/.perltidyrc'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
