use strict;
use Test::More tests => 3;

use AppConfig;
use Log::Dispatch::Configurator::AppConfig;
use Log::Dispatch::Config;

END { unlink "t/log.out" if -e "t/log.out" }

my $cfg_file = 't/section.ini';
ok(-f $cfg_file, "Config exists");

my $appconf = AppConfig->new({
    CREATE => 1,
    GLOBAL => {
	ARGCOUNT => AppConfig::ARGCOUNT_ONE(),
    },
});
$appconf->file($cfg_file);

my $config  = Log::Dispatch::Configurator::AppConfig->new($appconf, 'log');
isa_ok($config, 'Log::Dispatch::Configurator::AppConfig');

Log::Dispatch::Config->configure($config);

{
    my $disp = Log::Dispatch::Config->instance;
    isa_ok $disp->{outputs}->{file}, 'Log::Dispatch::File';
}
