use strict;
use Test::More tests => 3;

use Log::Dispatch::Config;
use Log::Dispatch::Configurator::Perl;

my $config = Log::Dispatch::Configurator::Perl->new('t/conf.pl');

Log::Dispatch::Config->configure($config);

my $disp = Log::Dispatch::Config->instance;

isa_ok $disp->{outputs}{file}, 'Log::Dispatch::File';
isa_ok $disp->{outputs}{screen}, 'Log::Dispatch::Screen';

my $another = Log::Dispatch::Config->instance;
is "$disp", "$another", "same instance - $disp";

END { unlink 't/log.out' if -e 't/log.out' }
