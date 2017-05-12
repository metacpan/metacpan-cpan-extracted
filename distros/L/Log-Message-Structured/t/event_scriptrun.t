use strict;
use warnings;
use Test::More;
use Sys::Hostname qw/ hostname /;

BEGIN { $0 = 't/event_scriptrun.t' }

use Log::Message::Structured::Event::ScriptRun;

sleep 2;

my $m = Log::Message::Structured::Event::ScriptRun->new;

is $m->script_name, 't/event_scriptrun.t';
ok $m->time >= 2;
is $m.'', 'Script t/event_scriptrun.t run on ' . hostname() . ' for ' . $m->time . 's';

done_testing;
