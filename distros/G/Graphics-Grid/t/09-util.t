#!perl

use strict;
use warnings;

use Test2::V0;

use Graphics::Grid::Util qw(:all);

is(dots_to_inches(300, 300), 1, 'dots_to_inches');
is(inches_to_dots(1, 300), 300, 'inches_to_dots');
is(dots_to_cm(300, 300), 2.54, 'dots_to_cm');
is(cm_to_dots(2.54, 300), 300, 'cm_to_dots');

done_testing;
