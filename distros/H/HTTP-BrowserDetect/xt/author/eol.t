use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/HTTP/BrowserDetect.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-detect.t',
    't/03-language.t',
    't/04-random-order.t',
    't/05_robot.t',
    't/99-warnings.t',
    't/add-field.pl',
    't/make-more-useragents.pl',
    't/more-useragents.json',
    't/perlcriticrc',
    't/useragents.json'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
