use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Graphics/Raylib.pm',
    'lib/Graphics/Raylib/Color.pm',
    'lib/Graphics/Raylib/Key.pm',
    'lib/Graphics/Raylib/Keyboard.pm',
    'lib/Graphics/Raylib/Mouse.pm',
    'lib/Graphics/Raylib/Shape.pm',
    'lib/Graphics/Raylib/Text.pm',
    'lib/Graphics/Raylib/Texture.pm',
    'lib/Graphics/Raylib/Util.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-colors.t',
    't/02-util.t',
    't/03-util-image.t',
    't/10-mouse.t',
    't/11-key.t',
    't/12-keyboard.t',
    't/20-use-ok.t',
    't/23-progress-bar.t',
    't/24-bitmap.t',
    't/25-tile.t',
    't/26-Imager.t',
    't/30-game-of-life.t',
    't/31-sierpinski.t',
    't/32-fractals.t',
    't/40-3d.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
