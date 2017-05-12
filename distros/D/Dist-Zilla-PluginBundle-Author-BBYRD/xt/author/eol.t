use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/MintingProfile/Author/BBYRD.pm',
    'lib/Dist/Zilla/PluginBundle/Author/BBYRD.pm',
    'lib/Pod/Weaver/PluginBundle/Author/BBYRD.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t'
);

eol_unix_ok($_, { trailing_whitespace => 0 }) foreach @files;
done_testing;
