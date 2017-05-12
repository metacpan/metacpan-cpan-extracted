use strict;
use Test::More tests => 3;

use Log::Dispatch::Config;
Log::Dispatch::Config->configure('t/log.cfg');

my $disp = Log::Dispatch->instance;

isa_ok $disp->{outputs}->{file}, 'Log::Dispatch::File';
isa_ok $disp->{outputs}->{screen}, 'Log::Dispatch::Screen';

my $another = Log::Dispatch->instance;
is "$disp", "$another", "same instance - $disp";

END { unlink 't/log.out' if -e 't/log.out' }
