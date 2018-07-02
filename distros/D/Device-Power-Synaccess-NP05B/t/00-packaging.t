#!/usr/bin/perl

## generic unit test for sanity-checking packaging details

use strict;
use warnings;
use Test::Most;

ok -e 'dist.ini',   'got dist.ini';
my ($name, $abstract) = dist_check();
isnt $name, "", 'dist.ini name set';
isnt $name, "Module-Name-Here", 'dist.ini name edited';
isnt $abstract, "", 'dist.ini abstract set';
isnt $abstract, "zzapp", 'dist.ini abstract edited';
my @unit_tests = glob('t/*.t');
ok @unit_tests > 1, "wrote unit tests";  # zzapp - update this if I write more generics

my $hr_ar = lib_check();
foreach my $hr (@$hr_ar) {
    my $lib = $hr->{lib};
    my $err = $hr->{err};
    ok $err eq "OK", "$lib: $err";
}

done_testing();
exit(0);

sub dist_check {
  my $name = '';
  my $abstract = '';
  my $fh;
  return ($name, $abstract) unless(open($fh, "<", "dist.ini"));
  while(defined(my $x = <$fh>)) {
    $name     = $1 if ($x =~ /^\s*name\s*=\s*([^\s]+)/);
    $abstract = $1 if ($x =~ /^\s*abstract\s*=\s*(.+?)\s*$/);
  }
  close($fh);
  return ($name, $abstract);
}

sub lib_check {
  return [{lib => './lib', err => 'missing'}] unless (-e './lib');
  my @errs;
  lib_check_helper(\@errs, "./lib");
  return \@errs;
}

sub lib_check_helper {
  my ($hr_ar, $dir) = @_;
  foreach my $f (glob("$dir/*")) {
    next if ($f =~ /\/\.[^\/]*$/);  # skip dotfiles
    if    (-d $f) { lib_check_helper($hr_ar, $f); }
    elsif ($f =~ /\.pm$/) { scan_module($hr_ar, $f); }
  }
  return;
}

sub scan_module {
  my ($hr_ar, $f) = @_;
  my $fh;
  unless(open($fh, "<", $f)) {
    push @$hr_ar, {lib => $f, err => "cannot open for reading ($!)"};
    return;
  }
  my @errs;
  my $got_strict;
  my $got_warnings;
  for my $i (0..50) {
    my $s = <$fh>;
    last unless(defined($s));
    push @errs, {lib => $f, err => "unedited boilerplate"} if ($s =~ /blahblah/);
    $got_strict   = 1 if ($s =~ /^\s*use strict/);
    $got_warnings = 1 if ($s =~ /^\s*use warnings/);
  }
  close($fh);
  push @errs, {lib => $f, err => 'declare strict'}   unless($got_strict);
  push @errs, {lib => $f, err => 'declare warnings'} unless($got_warnings);
  push @errs, {lib => $f, err => 'OK'} unless(@errs);
  push @$hr_ar, @errs;
  return;
}
