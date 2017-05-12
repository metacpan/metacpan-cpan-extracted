use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/MintingProfile/Author/RWSTAUNER.pm',
    'lib/Dist/Zilla/PluginBundle/Author/RWSTAUNER.pm',
    'lib/Dist/Zilla/PluginBundle/Author/RWSTAUNER/Minter.pm',
    'lib/Pod/Weaver/PluginBundle/Author/RWSTAUNER.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/configure.t',
    't/lib/Dist/Zilla/Plugin/No_Op_Releaser.pm',
    't/mint.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
