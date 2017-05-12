use strict;
use Test::More tests => 6;
use File::BaseDir;

my $rootdir = ($^O eq 'MSWin32') ? 'c:\\' : File::Spec->rootdir();

my $conf = File::BaseDir->new;

is(ref($conf), 'File::BaseDir', 'OO constructor works');

$ENV{XDG_DATA_DIRS} = '';
is_deeply( [$conf->xdg_data_dirs()],
           [ File::Spec->catdir($rootdir, qw/usr local share/),
             File::Spec->catdir($rootdir, qw/usr share/)         ],
	   'xdg_data_dirs default - OO');

$ENV{XDG_DATA_HOME} = 't';
is($conf->data_dirs('data'), File::Spec->catdir(qw/t data/),
	'data_dirs - OO');
is(File::BaseDir->data_dirs('data'), File::Spec->catdir(qw/t data/),
	'data_dirs - Module');

is($conf->data_home('data', 'test'), File::Spec->catfile(qw/t data test/),
	'data_home - OO');
is(File::BaseDir->data_home('data', 'test'), File::Spec->catfile(qw/t data test/),
	'data_home - Module');
