use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Graphics/Raylib.pm',
    'lib/Graphics/Raylib/Color.pm',
    'lib/Graphics/Raylib/Shape.pm',
    'lib/Graphics/Raylib/Text.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-init.t',
    't/02-fps.t',
    't/03-background.t',
    't/04-progress-bar.t',
    't/05-colors.t',
    't/10-game-of-life.t'
);

notabs_ok($_) foreach @files;
done_testing;
