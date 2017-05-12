use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl qw[:type];

#
can_ok 'Fl', 'FL_VERTICAL';
can_ok 'Fl', 'FL_HORIZONTAL';
can_ok 'Fl', 'FL_VERT_FILL_SLIDER';
can_ok 'Fl', 'FL_HOR_FILL_SLIDER';
can_ok 'Fl', 'FL_HOR_FILL_SLIDER';
can_ok 'Fl', 'FL_VERT_NICE_SLIDER';
can_ok 'Fl', 'FL_HOR_NICE_SLIDER';

# Check :type import tag
can_ok 'main', 'FL_VERTICAL';
can_ok 'main', 'FL_HORIZONTAL';
can_ok 'main', 'FL_VERT_FILL_SLIDER';
can_ok 'main', 'FL_HOR_FILL_SLIDER';
can_ok 'main', 'FL_HOR_FILL_SLIDER';
can_ok 'main', 'FL_VERT_NICE_SLIDER';
can_ok 'main', 'FL_HOR_NICE_SLIDER';

#
done_testing;
