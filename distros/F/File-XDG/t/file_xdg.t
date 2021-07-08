use strict;
use warnings;
use Test::More;
use File::XDG;
use File::Temp;
use Config;
use Path::Class qw( dir );
use File::Path qw(make_path);
use if $^O eq 'MSWin32', 'Win32';

our $base = $^O ne 'MSWin32'
  ? $ENV{HOME} || [getpwuid($>)]->[7]
  : Win32::GetFolderPath(Win32::CSIDL_LOCAL_APPDATA(), 1);

subtest 'env' => sub {
  local %ENV = %ENV;
  $ENV{XDG_CONFIG_HOME} = '/home/user/.config';
  $ENV{XDG_DATA_HOME} = '/home/user/.local/share';
  $ENV{XDG_CACHE_HOME} = '/home/user/.cache';
  $ENV{XDG_DATA_DIRS} = "/usr/local/share$Config{path_sep}/usr/share";
  $ENV{XDG_CONFIG_DIRS} = "/etc/xdg$Config{path_sep}/foo/bar";
  local $base = "/home/user";

  my $xdg = File::XDG->new(name => 'test');

  is($xdg->config_home, dir($base, '.config/test'), 'user-specific app configuration');
  is($xdg->data_home, dir($base, '.local/share/test'), 'user-specific app data');
  is($xdg->cache_home, dir($base, '.cache/test'), 'user-specific app cache');
  is($xdg->data_dirs, "/usr/local/share$Config{path_sep}/usr/share", 'system-wide data directories');
  is($xdg->config_dirs, "/etc/xdg$Config{path_sep}/foo/bar", 'system-wide configuration directories');

  is_deeply( [$xdg->data_dirs_list], [dir('/usr/local/share'),dir('/usr/share')], 'system-wide data directories as a list');
  is_deeply( [$xdg->config_dirs_list], [dir('/etc/xdg'),dir('/foo/bar')], 'system-wide configuration directories as a list');
};

subtest 'noenv' => sub {
  local %ENV = %ENV;
  delete $ENV{$_} for qw( XDG_DATA_HOME XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_DIRS XDG_CONFIG_DIRS );

  my $xdg = File::XDG->new(name => 'test');

  {
    is($xdg->config_home, dir($base, '.config/test'), 'user-specific app configuration');
    is($xdg->data_home, dir($base, '.local/share/test'), 'user-specific app data');
    is($xdg->cache_home, dir($base, '.cache/test'), 'user-specific app cache');
    if($^O eq 'MSWin32')
    {
      is($xdg->data_dirs, '', 'system-wide data directories');
      is($xdg->config_dirs, '', 'system-wide configuration directories');
      is_deeply( [$xdg->data_dirs_list], [], 'system-wide data directories as a list');
      is_deeply( [$xdg->config_dirs_list], [], 'system-wide configuration directories as a list');
    }
    else
    {
      is($xdg->data_dirs, '/usr/local/share:/usr/share', 'system-wide data directories');
      is($xdg->config_dirs, '/etc/xdg', 'system-wide configuration directories');
      is_deeply( [$xdg->data_dirs_list], ['/usr/local/share','/usr/share'], 'system-wide data directories as a list');
      is_deeply( [$xdg->config_dirs_list], ['/etc/xdg'], 'system-wide configuration directories as a list');
    }
  }
};

subtest 'lookup' => sub {
  local $ENV{HOME} = File::Temp->newdir();
  local $ENV{XDG_DATA_DIRS} = File::Temp->newdir();
  local $ENV{XDG_CONFIG_DIRS} = File::Temp->newdir();

  subtest 'data_home' => sub {
    test_lookup('data_home', 'data_dirs', 'lookup_data_file');
  };

  subtest 'config_home' => sub {
    test_lookup('config_home', 'config_dirs', 'lookup_config_file');
  };
};

sub test_lookup {
  my ($home_m, $dirs_m, $lookup_m) = @_;

  my $name = 'test';
  my $xdg = File::XDG->new(name => $name);

  my @subpath = ('subdir', 'filename');
  my $home = ($xdg->$home_m =~ /(.*)$name/)[0];
  my $dir  = $xdg->$dirs_m;

  make_file($home, @subpath);
  make_file($dir, @subpath);

  my $home_file = File::Spec->join($home, @subpath);
  my $dir_file = File::Spec->join($dir, @subpath);

  ok(-f $home_file, "created file in $home_m");
  ok(-f $dir_file, "created file in $dirs_m");

  isnt($home_file, $dir_file, "created distinct files in $home_m and $dirs_m");
  is($xdg->$lookup_m(@subpath), $home_file, "lookup found file in $home_m");
  unlink($home_file);
  is($xdg->$lookup_m(@subpath), $dir_file, "after removing file in $home_m, lookup found file in $dirs_m");
  unlink($dir_file);
  is($xdg->$lookup_m(@subpath), undef, "after removing file in $dirs_m, lookup did not find file");
}

sub make_file {
  my (@path) = @_;

  my $filename = pop @path;
  my $directory = File::Spec->join(@path);
  my $path = File::Spec->join($directory, $filename);

  make_path($directory);

  my $file = IO::File->new($path, 'w');
  $file->close;
}

done_testing;
