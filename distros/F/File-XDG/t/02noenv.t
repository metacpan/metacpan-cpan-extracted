use Test::More tests => 3;
use File::XDG;

my $xdg = File::XDG->new(name => 'test');

{
    local $ENV{HOME} = '/home/test';
    local $ENV{XDG_CONFIG_HOME};
    is($xdg->config_home, '/home/test/.config/test', 'user-specific app configuration');
    local $ENV{XDG_DATA_HOME};
    is($xdg->data_home, '/home/test/.local/share/test', 'user-specific app data');
    local $ENV{XDG_CACHE_HOME};
    is($xdg->cache_home, '/home/test/.cache/test', 'user-specific app cache');
}
