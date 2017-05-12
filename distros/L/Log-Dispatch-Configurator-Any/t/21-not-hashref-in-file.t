use strict;
use Test::More tests => 2;

use Log::Dispatch::Config;
use Log::Dispatch::Configurator::Any;

SKIP: {
    eval { require YAML::XS };
    skip 'no YAML::XS installed', 2 if $@;

    my $cfg_file = 't/cfg_file_bad.yml';
    ok(-f $cfg_file, "Config exists");
    
    eval{ Log::Dispatch::Configurator::Any->new($cfg_file) };
    like($@, qr/does not build a Hash/, 'does not build a Hash');
}
