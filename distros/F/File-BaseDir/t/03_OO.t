use strict;
use warnings;
use Test::More tests => 6;
use File::Spec;
use File::BaseDir;
use lib 't/lib';
use Helper qw( build_test_data );

my $conf = File::BaseDir->new;
isa_ok $conf, 'File::BaseDir';

{
  my $rootdir = ($^O eq 'MSWin32') ? 'c:\\' : File::Spec->rootdir();

  $ENV{XDG_DATA_DIRS} = '';
  is_deeply( [$conf->xdg_data_dirs()],
             [ File::Spec->catdir($rootdir, qw/usr local share/),
               File::Spec->catdir($rootdir, qw/usr share/)         ],
       'xdg_data_dirs default - OO');
}

{
  my $root = build_test_data;

  $ENV{XDG_DATA_HOME} = File::Spec->catdir($root, 't');
  is($conf->data_dirs('data'), File::Spec->catdir($root, qw/t data/),
    'data_dirs - OO');
  is(File::BaseDir->data_dirs('data'), File::Spec->catdir($root, qw/t data/),
    'data_dirs - Module');

  is($conf->data_home('data', 'test'), File::Spec->catfile($root, qw/t data test/),
    'data_home - OO');
  is(File::BaseDir->data_home('data', 'test'), File::Spec->catfile($root, qw/t data test/),
    'data_home - Module');
}
