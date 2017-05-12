use strict;
use warnings;

use Test::More;

use_ok 'Log::Message::Structured';

diag 'Testing Log::Message::Structured, version ' . Log::Message::Structured->VERSION;

use_ok 'Log::Message::Structured::Stringify::Sprintf';
use_ok 'Log::Message::Structured::Stringify::AsJSON';
use_ok 'Log::Message::Structured::Event::ScriptRun';

done_testing;

