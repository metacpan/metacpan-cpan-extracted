use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MediaWiki/CleanupHTML.pm',
    't/00-compile.t',
    't/data/English-Wikipedia-Perl-Page-2012-04-26.html',
    't/system.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
