use strict;
use Test::More tests => 3;

use Log::Dispatch::Config;
use Log::Dispatch::Configurator::Any;

SKIP: {
    eval { require Config::Tiny };
    skip 'no Config::Tiny installed', 3 if $@;

    my $cfg_file = 't/cfg_file.ini';
    ok(-f $cfg_file, "Config exists");

    my $config  = Log::Dispatch::Configurator::Any->new($cfg_file);
    isa_ok($config, 'Log::Dispatch::Configurator::Any');

    Log::Dispatch::Config->configure($config);

    {
        my $disp = Log::Dispatch::Config->instance;
        isa_ok $disp->{outputs}->{syslog}, 'Log::Dispatch::Syslog';
    }
}
