use strict;
use Test::More tests => 3;

use Log::Dispatch::Config;
use Log::Dispatch::Configurator;

my $config = Log::Dispatch::Configurator->new("/dev/null");
isa_ok $config, 'Log::Dispatch::Configurator';
is $config->{file}, '/dev/null';

Log::Dispatch::Config->configure($config);

eval {
    my $disp = Log::Dispatch::Config->instance;
};
like $@, qr/get_attrs_global is/, $@;


