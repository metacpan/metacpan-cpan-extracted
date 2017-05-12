use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl qw[:enum];

# :font
can_ok 'main', 'FL_BOLD';

# :version
can_ok 'main', 'FL_VERSION';

# :box
can_ok 'main', 'FL_NO_BOX';
can_ok 'main', 'FL_NO_LABEL';

# :chart
can_ok 'main', 'FL_BAR_CHART';

# :color
can_ok 'main', 'FL_BLACK';
can_ok 'main', 'fl_show_colormap';

# :button
can_ok 'main', 'FL_NORMAL_BUTTON';

# :when
can_ok 'main', 'FL_WHEN_NEVER';

# :keyboard
can_ok 'main', 'FL_F';

# :mouse
can_ok 'main', 'FL_LEFT_MOUSE';

# :align
can_ok 'main', 'FL_ALIGN_CENTER';

# :event
can_ok 'main', 'FL_LEFT_MOUSE';

#
done_testing;
