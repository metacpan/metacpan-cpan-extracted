package # Hide from PAUSE indexer
  Math::Histogram::Test;
use strict;
use warnings;

use Config qw(%Config);
use File::Spec;
use Capture::Tiny qw(capture);
use Exporter ();
use Test::More;

our @ISA = qw(Exporter);
our @EXPORT = qw(run_ctest is_approx axis_eq histogram_eq);

our ($USE_VALGRIND, $USE_GDB);

my $in_testdir = not(-d 't');
my $base_dir;
my $ctest_dir;

if ($in_testdir) {
  $base_dir = File::Spec->updir;
  $USE_VALGRIND = -e File::Spec->catfile(File::Spec->updir, 'USE_VALGRIND');
  $USE_GDB = -e File::Spec->catfile(File::Spec->updir, 'USE_GDB');
}
else {
  $base_dir = File::Spec->curdir;
  $USE_VALGRIND = -e 'USE_VALGRIND';
  $USE_GDB = -e 'USE_GDB';
}
$ctest_dir = File::Spec->catdir($base_dir, 'ctest');

my @ctests = glob( "$ctest_dir/*.c" );
my @exe = grep -f $_, map {s/\.c$/$Config{exe_ext}/; $_} @ctests;

sub locate_exe {
  my $exe = shift;
  if (-f $exe) {
    return $exe;
  }
  my $inctest = File::Spec->catfile($ctest_dir, $exe);
  if (-f $inctest) {
    return $inctest;
  }
  return;
}

sub run_ctest {
  my ($executable, $options) = @_;
  my $to_run = locate_exe($executable);

  return if not defined $to_run;

  #my ($stdout, $stderr) = capture {
    my @cmd;
    if ($USE_VALGRIND) {
      push @cmd, "valgrind", "--suppressions=" .  File::Spec->catfile($base_dir, 'perl.supp');
    }
    elsif ($USE_GDB) {
      push @cmd, "gdb";
    }
    push @cmd, $to_run, ref($options)?@$options:();
    note("@cmd");
    system(@cmd)
      and fail("C test did not exit with 0");
  #};
  #print $stdout;
  #warn $stderr if defined $stderr and $stderr ne '';
  return 1;
}

sub is_approx {
  my ($l, $r, $m) = @_;
  my $is_undef = !defined($l) || !defined($r);
  $l = "<undef>" if not defined $l;
  $r = "<undef>" if not defined $r;
  my $ok = ok(
    !$is_undef
    && $l+1e-9 > $r
    && $l-1e-9 < $r,
    $m
  );
  note("'$m' failed: $l != $r") if not $ok;
  return $ok;
}

sub axis_eq {
  my ($t, $ref, $name) = @_;
  isa_ok($t, 'Math::Histogram::Axis');

  is_approx($t->min, $ref->min, "$name: min");
  is_approx($t->max, $ref->max, "$name: max");
  is_approx($t->width, $ref->width, "$name: width");

  is($t->nbins, $ref->nbins, "$name: nbins")
    or return; # short circuit if nbins differs

  my $n = $ref->nbins;
  for my $ibin (1..$n) {
    is_approx($t->binsize($ibin), $ref->binsize($ibin), "$name, $ibin: binsize");
    is_approx($t->lower_boundary($ibin), $ref->lower_boundary($ibin), "$name, $ibin: lower_boundary");
    is_approx($t->upper_boundary($ibin), $ref->upper_boundary($ibin), "$name, $ibin: upper_boundary");
    is_approx($t->bin_center($ibin), $ref->bin_center($ibin), "$name, $ibin: bin_center");
    my ($lower, $center, $upper) = map $ref->$_($ibin), qw(lower_boundary bin_center upper_boundary);

    is($t->find_bin($lower), $ibin, "$name, $ibin: found lower bin boundary");
    is($t->find_bin($center), $ibin, "$name, $ibin: found bin center");
    is($t->find_bin($upper), $ibin+1, "$name, $ibin: found upper bin boundary");
  }

}

sub histogram_eq {
  my ($t, $ref, $name) = @_;

  is_approx($t->total, $ref->total, "$name: total");
  is($t->nfills, $ref->nfills, "$name: nfills");
  is($t->ndim, $ref->ndim, "$name: ndim")
    or return;

  my $ndim = $t->ndim;
  foreach my $i (0..$ndim-1) {
    axis_eq($t->get_axis($i), $ref->get_axis($i), "$name (axis $i)");
  }

  ok($ref->data_equal_to($t), "$name: data equal to");
}

1;
