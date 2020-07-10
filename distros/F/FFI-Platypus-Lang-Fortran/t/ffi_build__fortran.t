use strict;
use warnings;
use Test::More 0.98;
use lib 't/lib';
use Test::Cleanup;
use FFI::Build;
use FFI::Build::Platform;
use File::Temp qw( tempdir );
use Capture::Tiny qw( capture_merged );
use File::Spec;
use File::Path qw( rmtree );
use FFI::Platypus 1.00;
use File::Glob qw( bsd_glob );

$ENV{FFI_PLATYPUS_DLERROR} = 1;

subtest 'Fortran' => sub {

  plan skip_all => 'Test requires Fortran compiler'
    unless eval { FFI::Build::Platform->which(FFI::Build::Platform->for) };

  plan skip_all => 'Test requires FFI::Platypus::Lang::Fortran'
    unless eval { require FFI::Platypus::Lang::Fortran };

  my $build = FFI::Build->new('foo',
    dir       => tempdir( "tmpbuild.XXXXXX", DIR => 'corpus/ffi_build/project-fortran' ),
    buildname => "tmpbuild.$$.@{[ time ]}",
    verbose   => 1,
  );

  $build->source('corpus/ffi_build/project-fortran/add*.f*');
  note "$_" for $build->source;

  my($out, $dll, $error) = capture_merged {
    my $dll = eval { $build->build };
    ($dll, $@);
  };

  ok $error eq '', 'no error';

  if($error)
  {
    diag $out;
    return;
  }
  else
  {
    note $out;
  }

  my $ffi = FFI::Platypus->new( api => 1 );
  $ffi->lang('Fortran');
  $ffi->lib($dll);

  my $ok = 1;

  $ok &&= is(
    eval { $ffi->function( add1 => [ 'integer*', 'integer*' ] => 'integer' )->call(\1,\2) } || diag($@),
    3,
    'FORTRAN 77',
  );

  $ok &&= is(
    eval { $ffi->function( add2 => [ 'integer*', 'integer*' ] => 'integer' )->call(\1,\2) } || diag($@),
    3,
    'Fortran 90',
  );

  $ok &&= is(
    eval { $ffi->function( add3 => [ 'integer*', 'integer*' ] => 'integer' )->call(\1,\2) } || diag($@),
    3,
    'Fortran 95',
  );

  unless($ok)
  {
    diag("build output:\n$out");
    if(my $nm = FFI::Build::Platform->which('nm'))
    {
      diag capture_merged {
        my @cmd = ('nm', $build->file->path);
        print "+ @cmd\n";
        system @cmd;
        ();
      };
    }
    if(my $ldd = FFI::Build::Platform->which('ldd'))
    {
      diag capture_merged {
        my @cmd = ('ldd', $build->file->path);
        print "+ @cmd\n";
        system @cmd;
        ();
      };
    }
  }

  cleanup(
    $build->file->dirname,
    File::Spec->catdir(qw( corpus ffi_build project-fortran ), $build->buildname)
  );

};

done_testing;
