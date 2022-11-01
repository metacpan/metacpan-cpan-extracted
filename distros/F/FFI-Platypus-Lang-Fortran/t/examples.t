use Test2::V0 -no_srand => 1;
use File::Which qw( which );
use File::Glob qw( bsd_glob );
use File::chdir;
use lib 't/lib';
use Test::Cleanup;

BEGIN {
  plan skip_all => 'test requires Capture::Tiny'
    unless eval q{ use Capture::Tiny qw( capture_merged ); 1 };
}

plan skip_all => 'developer test set FFI_PLATYPUS_LANG_FORTRAN_TEST_EXAMPLES=1 to run' unless $ENV{FFI_PLATYPUS_LANG_FORTRAN_TEST_EXAMPLES} || $ENV{CIPSOMETHING};
plan skip_all => 'requires gfortran' unless which 'gfortran';
plan tests => 2;

my @lib;

if(-d 'blib')
{
  push @lib, '-Mblib';
}
else
{
  $ENV{PERL_FILE_SHAREDIR_DIST} = join '=', 'FFI-Platypus-Lang-Fortra', "$CWD/share";
  push @lib, '-I../lib';
}

chdir 'examples';

my @for_files = bsd_glob '*.f{,90,95}';
my @pl_files  = grep !/^compile\.pl$/, bsd_glob '*.pl';

subtest 'compile fortran' => sub {

  plan tests => scalar @for_files;

  foreach my $for_file (@for_files)
  {
    my $so_file = "$for_file";
    $so_file =~ s/\..*$/.so/;
    cleanup $so_file;
    my @cmd = ('gfortran', '-fPIC', '-shared', -o => $so_file, $for_file);
    my($out,$err) = capture_merged {
      print "+@cmd\n";
      system @cmd;
      $?;
    };
    if(is $?, 0, "$for_file")
    {
      note $out if $out;
    }
    else
    {
      diag $out if $out;
    }
  }

};

subtest 'run perl' => sub {

  plan tests => scalar @pl_files;

  foreach my $pl_file (@pl_files)
  {
    my @cmd = ($^X, @lib, $pl_file);
    my($out,$err) = capture_merged {
      print "+@cmd\n";
      system @cmd;
      $?;
    };
    if(is $?, 0, "$pl_file")
    {
      note "+ @cmd";
      note $out if $out;
    }
    else
    {
      diag $out if $out;
    }
  }

};

done_testing;
