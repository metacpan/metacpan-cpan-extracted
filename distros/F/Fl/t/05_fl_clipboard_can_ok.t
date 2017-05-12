use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl qw[:clipboard];

#
can_ok 'Fl', 'clipboard_contains';
can_ok 'Fl', 'copy';
can_ok 'Fl', 'dnd';
can_ok 'Fl', 'paste';
can_ok 'Fl', 'selection';

# Check :event import tag
can_ok 'main', 'clipboard_contains';
can_ok 'main', 'copy';
can_ok 'main', 'dnd';
can_ok 'main', 'selection';

#
done_testing;
