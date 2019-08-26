use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MediaWiki/CleanupHTML.pm',
    't/00-compile.t',
    't/data/English-Wikipedia-Perl-Page-2012-04-26.html',
    't/system.t'
);

notabs_ok($_) foreach @files;
done_testing;
