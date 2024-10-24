use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/Stenciller/HtmlExamples.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/corpus/01-test.stencil',
    't/corpus/DZT/lib/DZT.pm',
    't/corpus/template.html'
);

notabs_ok($_) foreach @files;
done_testing;
