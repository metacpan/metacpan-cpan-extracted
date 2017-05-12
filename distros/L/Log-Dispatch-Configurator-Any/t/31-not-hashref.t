use strict;
use Test::More tests => 1;

use Log::Dispatch::Config;
use Log::Dispatch::Configurator::Any;

my $defaults = [
    dispatchers => ['screen'],
    screen => {
        class     => 'Log::Dispatch::Screen',
        min_level => 'debug',
        max_level => 'emergency',
        stderr    => 0,
    },
];

eval{ Log::Dispatch::Configurator::Any->new($defaults) };
like($@, qr/Config must be hashref or filename/);

