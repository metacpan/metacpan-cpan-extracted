use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Test::Cleanup;
use FFI::Build;
use FFI::Build::File::Fortran;
use FFI::Build::Platform;
use File::Which qw( which );
use File::Basename qw( basename );
use File::ShareDir::Dist qw( dist_config );
use Capture::Tiny qw( capture_merged );

plan skip_all => 'Test requires Fortran compiler'
  unless eval { FFI::Build::Platform->which(FFI::Build::Platform->for) };

my $config = dist_config 'FFI-Platypus-Lang-Fortran';
my $lib;

subtest 'build' => sub {

  my @fall;

  foreach my $version (qw( f77 f90 f95 ))
  {

    subtest "compile $version" => sub {

      skip_all "test requires $version compiler"
        unless $version eq 'f77' || which($config->{f77}->{$version});

      my $ext = $version eq 'f77' ? 'f' : $version;

      my $file = FFI::Build::File::Fortran->new(['t', 'ffi', "${version}add.$ext"]);
      note "path = @{[ $file->path ]}";
      push @fall, "t/ffi/${version}add.$ext";

      is
        $file,
        object {
          call [ isa => 'FFI::Build::File::Fortran' ] => T();
          call [ isa => 'FFI::Build::File::Base' ] => T();
          call default_suffix   => '.f';
          call default_encoding => ':utf8';
        },
        'create file object';

      cleanup 't/ffi/_build';

      my @obj = $file->build_item;

      is
        \@obj,
        array {
          item object {
            call [ isa => 'FFI::Build::File::Object' ] => T();
          };
          end;
        },
        'build';

    };
  }

  subtest 'link' => sub {

    note "source = @fall";

    my $build = FFI::Build->new(
      'test',
      source  => \@fall,
      dir     => 't/ffi',
      verbose => 2,
    );

    my($out, $error, $lib) = capture_merged {
      $lib = eval { $DB::single = 1; $build->build };
      ($@, $lib);
    };

    is "$error", "", '$build->build';
    note $out if $out ne '';

    if(defined $lib)
    {
      note "lib = $lib";
      cleanup $lib;
    }

  };

};

subtest call => sub {

  require FFI::Platypus;
  my $ffi = FFI::Platypus->new( api => 2, lang => 'Fortran', lib => [$lib] );

  subtest 'Fortran 77' => sub {

    $ffi->attach( iadd => ['integer*', 'integer*'] => 'integer');
    my $r = iadd(\1,\2);
    is $r, 3, 'iadd(\1,\2) = 3' or diag sprintf("r = %x\n", $r);

  };

  subtest 'Fortran 90' => sub {

    plan skip_all => 'test requires Fortran 90' unless $ffi->find_symbol('f90add');

    $ffi->attach( f90add => ['integer*', 'integer*'] => 'integer');
    is f90add(\1,\2), 3, 'add(\1,\2) = 3';

  };

  subtest 'Fortran 95' => sub {

    plan skip_all => 'test requires Fortran 95' unless $ffi->find_symbol('f95add');

    $ffi->attach( f95add => ['integer*', 'integer*'] => 'integer');
    is f95add(\1,\2), 3, 'add(\1,\2) = 3';

  };

};

done_testing;
