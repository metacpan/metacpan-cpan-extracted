use Test2::V0 -no_srand => 1;
use FindBin ();
use File::ShareDir::Dist qw( dist_share );
use Path::Tiny qw( path );

sub require_ok ($);

my $ok = subtest 'use all' => sub {
  require_ok 'FFI::TinyCC';
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

  my $share = path($FindBin::Bin)->parent->child('share');
  my $log = $share->child('build.log');
  
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
    my $dist_dir = dist_share('FFI-TinyCC');
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
    my $dist_dir = dist_share('Alien-TinyCC');
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

done_testing;

sub require_ok ($)
{
  # special case of when I really do want require_ok.
  # I just want a test that checks that the modules
  # will compile okay.  I won't be trying to use them.
  my($mod) = @_;
  my $ctx = context();
  eval qq{ require $mod };
  my $error = $@;
  my $ok = !$error;
  $ctx->ok($ok, "require $mod");
  $ctx->diag("error: $error") if $error ne '';
  $ctx->release;
}
