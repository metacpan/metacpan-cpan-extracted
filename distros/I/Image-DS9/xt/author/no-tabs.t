use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Image/DS9.pm',
    'lib/Image/DS9.pod',
    'lib/Image/DS9/Command.pm',
    'lib/Image/DS9/Constants.pm',
    'lib/Image/DS9/Grammar.pm',
    'lib/Image/DS9/OldConstants.pm',
    'lib/Image/DS9/PConsts.pm',
    'lib/Image/DS9/Parser.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/array.t',
    't/bin.t',
    't/blink.t',
    't/cmap.t',
    't/common.pl',
    't/contour.t',
    't/crosshair.t',
    't/cursor.t',
    't/dss.t',
    't/file.t',
    't/fits.t',
    't/frame.t',
    't/grid.t',
    't/iconify.t',
    't/lib/TestServer.pm',
    't/lower.t',
    't/minmax.t',
    't/mode.t',
    't/nameserver.t',
    't/orient.t',
    't/page.t',
    't/pan.t',
    't/pixeltable.t',
    't/print.t',
    't/raise.t',
    't/regions.t',
    't/rotate.t',
    't/scale.t',
    't/single.t',
    't/smooth.t',
    't/tile.t',
    't/version.t',
    't/view.t',
    't/wcs.t',
    't/zoom.t'
);

notabs_ok($_) foreach @files;
done_testing;
