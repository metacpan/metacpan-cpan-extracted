use strict;
use Test::More tests => 6;

use Log::Dispatch::Config;

package Foo::Logger;
use base qw(Log::Dispatch::Config);

package Bar::Logger;
use base qw(Log::Dispatch::Config);

package main;
Foo::Logger->configure('t/log.cfg');
Bar::Logger->configure('t/log.ini');

my $foo = Foo::Logger->instance;
my $bar = Bar::Logger->instance;
my $bar2 = Bar::Logger->instance;

isa_ok $foo, 'Foo::Logger';
isa_ok $foo, 'Log::Dispatch::Config';
isa_ok $bar, 'Bar::Logger';
isa_ok $bar, 'Log::Dispatch::Config';

isnt "$foo", "$bar", 'not same one';
is "$bar", "$bar2", 'same one';

END { unlink 't/log.out' if -e 't/log.out' }
