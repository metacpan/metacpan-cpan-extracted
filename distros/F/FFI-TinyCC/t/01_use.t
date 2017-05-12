use strict;
use warnings;
use FindBin ();
use Test::More tests => 1;
use File::ShareDir qw( dist_dir );
use Path::Class qw( dir );

my $ok = subtest 'use all' => sub {
  plan tests => 2;
  use_ok 'FFI::TinyCC';
  use_ok 'FFI::TinyCC::Inline';
};

unless($ok)
{
  diag '';
  diag '';
  diag '';
  diag 'DID NOT WORK';
  diag '';
  diag '';
  diag '';

  my $share = dir($FindBin::Bin)->parent->subdir('share');
  my $log = $share->file('build.log');
  
  diag "=== $log ===";
  if(-e $log)
  {
    diag $log->slurp;
  }
  else
  {
    diag "NO LOG";
  }

  my $dir = $^O eq 'MSWin32' ? 'cmd /c dir /s' : 'ls -lR' ;

  diag "=== $share ===";
  diag "+ $dir $share";
  diag `$dir $share`;
  
  eval { 
    my $dist_dir = dist_dir('FFI-TinyCC');
    diag "=== $dist_dir ===";
    diag "+ $dir $dist_dir";
    diag `$dir $dist_dir`;
  };
  if(my $error = $@)
  {
    diag "=== no dist_dir(FFI-TinyCC) ===";
    diag $error;
  }

  eval { 
    my $dist_dir = dist_dir('Alien-TinyCC');
    diag "=== $dist_dir ===";
    diag "+ $dir $dist_dir";
    diag `$dir $dist_dir`;
  };
  if(my $error = $@)
  {
    diag "=== no dist_dir(Alien-TinyCC) ===";
    diag $error;
  }
  
  eval {
    require Alien::TinyCC;
    my $inc = Alien::TinyCC->libtcc_include_path;
    my $lib = Alien::TinyCC->libtcc_library_path;
    diag "=== $inc ===";
    diag "+ $dir $inc";
    diag `$dir $inc`;
    diag "=== $lib ===";
    diag "+ $dir $lib";
    diag `$dir $lib`;
  };
  if(my $error = $@)
  {
    diag "=== no Alien::TinyCC ===";
    diag $error;
  }
  
}

