use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'Changes',
    'GPLv3',
    'VERSION',
    'lib/Dist/Zilla/Role/ErrorLogger.pm',
    't/error-logger.t',
    't/lib/FileGatherer.pm',
    'xt/aspell-en.pws',
    'xt/perlcritic.ini'
);

notabs_ok($_) foreach @files;
done_testing;
