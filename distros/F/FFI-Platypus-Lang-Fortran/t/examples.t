use strict;
use warnings;
use Test::More;
use File::Which qw( which );
use File::Glob qw( bsd_glob );

BEGIN {
  plan skip_all => 'test requires Capture::Tiny'
    unless eval q{ use Capture::Tiny qw( capture_merged ); 1 };
}

plan skip_all => 'developer test' unless ($ENV{USERNAME}||'') eq 'ollisg' || $ENV{TRAVIS};
plan skip_all => 'requires gfortran' unless which 'gfortran';
plan skip_all => 'run ./Build first' unless -d 'blib';
plan tests => 2;

chdir 'examples';

my @for_files = bsd_glob '*.f{,90,95}';
my @pl_files  = grep !/^compile\.pl$/, bsd_glob '*.pl';

subtest 'compile fortran' => sub {

  plan tests => scalar @for_files;

  foreach my $for_file (@for_files)
  {
    my $so_file = "lib$for_file";
    $so_file =~ s/\..*$/.so/;
    my @cmd = ('gfortran', '-fPIC', '-shared', -o => $so_file, $for_file);
    my($out,$err) = capture_merged {
      system @cmd;
      $?;
    };
    is $?, 0, "$for_file";
    note "+ @cmd";
    note $out if $out;
  }

};

subtest 'run perl' => sub {

  plan tests => scalar @pl_files;

  foreach my $pl_file (@pl_files)
  {
    my @cmd = ($^X, '-Mblib', $pl_file);
    my($out,$err) = capture_merged {
      system @cmd;
      $?;
    };
    is $?, 0, "$pl_file";
    note "+ @cmd";
    note $out if $out;
  }

};
