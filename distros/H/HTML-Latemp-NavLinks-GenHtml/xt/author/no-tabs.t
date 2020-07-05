use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/HTML/Latemp/NavLinks/GenHtml.pm',
    'lib/HTML/Latemp/NavLinks/GenHtml/ArrowImages.pm',
    'lib/HTML/Latemp/NavLinks/GenHtml/Text.pm',
    't/00-compile.t',
    't/01-run.t'
);

notabs_ok($_) foreach @files;
done_testing;
