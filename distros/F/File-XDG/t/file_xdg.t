use strict;
use warnings;
use Test::More;
use File::XDG;
use File::Temp;
use File::Spec;
use Config;
use Path::Class qw( dir );
use Path::Tiny qw( path );
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

subtest 'exe_dir' => sub {
  my $home = File::Temp->newdir;
  local $ENV{HOME} = $home;
  local *Win32::GetFolderPath = sub { return $home };

  my $xdg = File::XDG->new( name => 'foo' );

  is($xdg->exe_dir, undef);

  mkdir "$ENV{HOME}/.local" or die;
  mkdir "$ENV{HOME}/.local/bin" or die;

  ok(-d $xdg->exe_dir);
};

subtest 'lookup' => sub {
  my $data   = File::Temp->newdir;
  my $config = File::Temp->newdir;
  local $ENV{XDG_DATA_DIRS}   = $data;
  local $ENV{XDG_CONFIG_DIRS} = $config;

  subtest 'data_home' => sub {
    test_lookup('data_home', 'data_dirs', 'lookup_data_file');
  };

  subtest 'config_home' => sub {
    test_lookup('config_home', 'config_dirs', 'lookup_config_file');
  };
};

subtest 'api' => sub {

  my $dir = path(__FILE__)->parent->stringify;

  subtest 'api = 0' => sub {
    my $xdg = File::XDG->new(name => 'foo');
    isa_ok($xdg->_file(__FILE__), 'Path::Class::File');
    isa_ok($xdg->_dir($dir), 'Path::Class::Dir');
  };

  subtest 'api = 1' => sub {
    my $xdg = do {
      local $SIG{__WARN__} = sub {
        if($_[0] =~ /^Note: experimental use of api = 1/)
        {
          note $_[0];
        }
        else
        {
          CORE::warn(@_);
        }
      };
      File::XDG->new(name => 'foo', api => 1);
    };
    isa_ok($xdg->_file(__FILE__), 'Path::Tiny');
    isa_ok($xdg->_dir($dir), 'Path::Tiny');
  };

};

subtest 'path_class' => sub {

  my $dir = path(__FILE__)->parent->stringify;

  subtest 'Path::Class' => sub {
    my $xdg = File::XDG->new(name => 'foo', path_class => 'Path::Class');
    isa_ok($xdg->_file(__FILE__), 'Path::Class::File');
    isa_ok($xdg->_dir($dir), 'Path::Class::Dir');
  };

  subtest 'Path::Tiny' => sub {
    my $xdg = File::XDG->new(name => 'foo', path_class => 'Path::Tiny');
    isa_ok($xdg->_file(__FILE__), 'Path::Tiny');
    isa_ok($xdg->_dir($dir), 'Path::Tiny');
  };

  subtest 'File::Spec' => sub {
    my $xdg = File::XDG->new(name => 'foo', path_class => 'File::Spec');
    is($xdg->_file(__FILE__), File::Spec->catfile(__FILE__));
    is($xdg->_dir($dir), File::Spec->catdir($dir));
  };

  subtest 'coderef' => sub {
    my $xdg = File::XDG->new(name => 'foo', path_class => sub { \@_ });
    isa_ok($xdg->_file(__FILE__), 'ARRAY');
    isa_ok($xdg->_dir($dir), 'ARRAY');
  };

  subtest 'arrayref' => sub {
    my $xdg = File::XDG->new(name => 'foo', path_class => [ sub { 1 }, sub { 2 } ]);
    is($xdg->_file(__FILE__), 1);
    is($xdg->_dir($dir), 2);
  };

};

subtest 'strict - operating system' => sub {

  if($^O eq 'MSWin32')
  {
    local $@ = '';
    eval {
      File::XDG->new( name => 'foo', strict => 1 );
    };
    like "$@", qr/^XDG base directory specification cannot strictly implemented on Windows/;
  }
  else
  {
    my $xdg = File::XDG->new( name => 'foo', strict => 1 );
    isa_ok $xdg, 'File::XDG';
  }

};

subtest 'runtime_home' => sub {

  my @args;
  push @args, name   => 'foo';
  push @args, strict => 1 if $^O ne 'MSWin32';

  my $dir = File::Temp->newdir;
  local $ENV{XDG_RUNTIME_DIR} = $dir;
  mkdir "$dir/foo" or die;

  ok(
    -d File::XDG->new(@args)->runtime_home
  );

  delete $ENV{XDG_RUNTIME_DIR};

  is(
    File::XDG->new(@args)->runtime_home,
    undef,
  );

};

sub test_lookup {
  my ($home_m, $dirs_m, $lookup_m) = @_;

  subtest 'api = 0' => sub {

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
  };

  subtest 'api = 1' => sub {

    my $name = 'test';
    my @warn;

    my $xdg = do {
      local $SIG{__WARN__} = sub {
        if($_[0] =~ /^Note: experimental use of api = 1/)
        {
          push @warn, $_[0] if $_[0] =~ /^Note: experimental use of api = 1/;
        }
        else
        {
          CORE::warn(@_);
        }
      };
      File::XDG->new(name => $name, api => 1);
    };

    is scalar(@warn), 1, 'exactly one warning about experimental api';

    my @subpath = ($name, 'filename');
    my $home = ($xdg->$home_m =~ /(.*)$name/)[0];
    my $dir  = $xdg->$dirs_m;

    make_file($home, @subpath);
    make_file($dir, @subpath);

    my $home_file = path($home, @subpath)->stringify;
    my $dir_file = path($dir, @subpath)->stringify;

    ok(-f $home_file, "created file in $home_m");
    ok(-f $dir_file, "created file in $dirs_m");

    isnt($home_file, $dir_file, "created distinct files in $home_m and $dirs_m");
    is($xdg->$lookup_m($subpath[-1]), $home_file, "lookup found file in $home_m");
    unlink($home_file);
    is($xdg->$lookup_m($subpath[-1]), $dir_file, "after removing file in $home_m, lookup found file in $dirs_m");
    unlink($dir_file);
    is($xdg->$lookup_m($subpath[-1]), undef, "after removing file in $dirs_m, lookup did not find file");
  };
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
