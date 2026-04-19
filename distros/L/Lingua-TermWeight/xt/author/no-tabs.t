use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Lingua/TermWeight.pm',
    'lib/Lingua/TermWeight/WordCounter/Lossy.pm',
    'lib/Lingua/TermWeight/WordCounter/Simple.pm',
    'lib/Lingua/TermWeight/WordSegmenter/LetterNgram.pm',
    'lib/Lingua/TermWeight/WordSegmenter/SplitBySpace.pm',
    't/00-compile.t',
    't/01-basic.t',
    't/02-letter-n-gram.t',
    't/03-split-by-space.t'
);

notabs_ok($_) foreach @files;
done_testing;
