use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/Author/HAYOBAAN/LinkCheck.pm',
    'lib/Dist/Zilla/Plugin/Author/HAYOBAAN/NextVersion.pm',
    'lib/Dist/Zilla/PluginBundle/Author/HAYOBAAN.pm',
    'lib/Pod/Weaver/PluginBundle/Author/HAYOBAAN.pm',
    'lib/Pod/Weaver/Section/Author/HAYOBAAN/Bugs.pm',
    't/00-compile.t',
    't/hayobaan.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
