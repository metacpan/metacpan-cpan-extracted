use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/OnlyCorePrereqs.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-deprecated.t',
    't/03-specific-version.t',
    't/04-no-check-module-versions.t',
    't/05-check-dual-life-versions.t',
    't/06-phases.t',
    't/07-skip.t',
    't/08-perl-prereq.t',
    't/09-also-disallow.t',
    't/zzz-check-breaks.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
