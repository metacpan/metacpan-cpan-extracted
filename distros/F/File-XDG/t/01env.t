use Test::More tests => 5;
use File::XDG;

my $xdg = File::XDG->new(name => 'test');

{
    local $ENV{XDG_CONFIG_HOME} = '/home/user/.config';
    ok($xdg->config_home eq '/home/user/.config/test', 'user-specific app configuration');
}
{
    local $ENV{XDG_DATA_HOME} = '/home/user/.local/share';
    ok($xdg->data_home eq '/home/user/.local/share/test', 'user-specific app data');
}
{
    local $ENV{XDG_CACHE_HOME} = '/home/user/.cache';
    ok($xdg->cache_home eq '/home/user/.cache/test', 'user-specific app cache');
}
{
    local $ENV{XDG_DATA_DIRS} = '/usr/local/share:/usr/share';
    ok($xdg->data_dirs eq '/usr/local/share:/usr/share', 'system-wide data directories');
}
{
    local $ENV{XDG_CONFIG_DIRS} = '/etc/xdg';
    ok($xdg->config_dirs eq '/etc/xdg', 'system-wide configuration directories');
}
