#!/usr/bin/perl

use warnings;
use strict;

use Event qw(queue_pending);

# Zefram <zefram@fysh.org>
#
# If you already have a signal watcher, and then start a second one for
# the same signal, the counting continues unaffected by the start of
# the second watcher.  Both watchers will generate events for a signal
# received shortly before the second one was started.

Event->signal(signal => "USR1",
        cb => sub { print "handler 0 got hits=", $_[0]->hits, "\n"; });
kill "USR1" => 0;

# If "queue_pending();" is added to the program, immediately before
# the creation of the second watcher, then it produces different output.
#
# queue_pending();

Event->signal(signal => "USR1",
        cb => sub { print "handler 1 got hits=", $_[0]->hits, "\n"; });
kill "USR1" => 0;
Event::loop;

