use strict;
use Test::More tests => 12;

use_ok('File::BaseDir', qw/:vars/);

my $rootdir = ($^O eq 'MSWin32') ? 'c:\\' : File::Spec->rootdir();
ok(length($ENV{HOME}), 'HOME defined');

$ENV{XDG_CONFIG_HOME} = '';
ok( xdg_config_home() eq File::Spec->catdir($ENV{HOME}, qw/.config/),
	'xdg_config_home default');
$ENV{XDG_CONFIG_HOME} = 'test123';
ok( xdg_config_home() eq 'test123', 'xdg_data_home set');

$ENV{XDG_CONFIG_DIRS} = '';
is_deeply( [xdg_config_dirs()],
           [ File::Spec->catdir($rootdir, qw/etc xdg/) ],
	   'xdg_config_dirs default');
$ENV{XDG_CONFIG_DIRS} = './t:foo:bar';
is_deeply( [xdg_config_dirs()],
           [File::Spec->catdir('.', 't'), 'foo', 'bar'],
	   'xdg_data_dirs set');

$ENV{XDG_DATA_HOME} = '';
ok( xdg_data_home() eq File::Spec->catdir($ENV{HOME}, qw/.local share/),
	'xdg_data_home default');
$ENV{XDG_DATA_HOME} = 'test123';
ok( xdg_data_home() eq 'test123', 'xdg_data_home set');

$ENV{XDG_DATA_DIRS} = '';
is_deeply( [xdg_data_dirs()],
           [ File::Spec->catdir($rootdir, qw/usr local share/),
             File::Spec->catdir($rootdir, qw/usr share/)         ],
	   'xdg_data_dirs default');
$ENV{XDG_DATA_DIRS} = './t:foo:bar';
is_deeply( [xdg_data_dirs()],
           [File::Spec->catdir('.', 't'), 'foo', 'bar'],
	   'xdg_data_dirs set');

$ENV{XDG_CACHE_HOME} = '';
ok( xdg_cache_home() eq File::Spec->catdir($ENV{HOME}, qw/.cache/),
	'xdg_cache_home default');
$ENV{XDG_CACHE_HOME} = 'test123';
ok( xdg_cache_home() eq 'test123', 'xdg_cache_home set');

