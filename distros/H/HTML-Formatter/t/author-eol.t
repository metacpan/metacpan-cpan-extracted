
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print "1..0 # SKIP these tests are for testing by the author\n";
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/HTML/FormatMarkdown.pm',
    'lib/HTML/FormatPS.pm',
    'lib/HTML/FormatRTF.pm',
    'lib/HTML/FormatText.pm',
    'lib/HTML/Formatter.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_ps.t',
    't/02_rtf.t',
    't/03_text.t',
    't/04_md.t',
    't/data/expected/test.md',
    't/data/expected/test.ps',
    't/data/expected/test.rtf',
    't/data/expected/test.txt',
    't/data/expected/unicode.md',
    't/data/expected/unicode.ps',
    't/data/expected/unicode.rtf',
    't/data/expected/unicode.txt',
    't/data/in/test.html',
    't/data/in/unicode.html',
    't/lib/Test/HTML/Formatter.pm',
    't/rt111783.t',
    't/rt69426.t',
    't/support/generate_results.pl'
);

eol_unix_ok($_, { trailing_whitespace => 0 }) foreach @files;
done_testing;
