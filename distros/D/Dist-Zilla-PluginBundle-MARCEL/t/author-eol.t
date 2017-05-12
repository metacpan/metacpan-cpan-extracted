
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/InlineFilesMARCEL.pm',
    'lib/Dist/Zilla/PluginBundle/MARCEL.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/perlcriticrc'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
