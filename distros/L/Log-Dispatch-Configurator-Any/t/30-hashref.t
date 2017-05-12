use strict;
use Test::More tests => 2;

use Log::Dispatch::Config;
use Log::Dispatch::Configurator::Any;

my $defaults = {
    dispatchers => ['screen'],
    screen => {
        class     => 'Log::Dispatch::Screen',
        min_level => 'debug',
        max_level => 'emergency',
        stderr    => 0,
    },
};

my $config  = Log::Dispatch::Configurator::Any->new($defaults);
isa_ok($config, 'Log::Dispatch::Configurator::Any');

Log::Dispatch::Config->configure($config);

{
    my $disp = Log::Dispatch::Config->instance;
    isa_ok $disp->{outputs}->{screen}, 'Log::Dispatch::Screen';
}
