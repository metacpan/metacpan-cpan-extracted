use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl qw[:color];

# Check :color import tag
can_ok 'main', 'FL_BLACK';
can_ok 'main', 'fl_show_colormap';

#
done_testing;


