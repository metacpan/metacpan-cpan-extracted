use strict;
use Test::More;

my @subs = qw( io_bind io_ns_bind timer_bind timer_ns_bind periodic_bind periodic_ns_bind signal_bind signal_ns_bind child_bind child_ns_bind idle_bind idle_ns_bind prepare_bind prepare_ns_bind check_bind check_ns_bind ) ;

plan(tests => 2);

use_ok("EV::Watcher::Bind");
can_ok("EV", @subs);
