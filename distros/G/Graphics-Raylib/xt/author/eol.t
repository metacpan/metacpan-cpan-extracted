use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Graphics/Raylib.pm',
    'lib/Graphics/Raylib/Color.pm',
    'lib/Graphics/Raylib/Mouse.pm',
    'lib/Graphics/Raylib/Shape.pm',
    'lib/Graphics/Raylib/Text.pm',
    'lib/Graphics/Raylib/Util.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-colors.t',
    't/02-util.t',
    't/10-mouse.t',
    't/20-init.t',
    't/21-fps.t',
    't/22-background.t',
    't/23-progress-bar.t',
    't/24-bitmap.t',
    't/30-game-of-life.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
