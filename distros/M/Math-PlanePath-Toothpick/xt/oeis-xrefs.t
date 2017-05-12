#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.


# Check that OEIS A-numbers listed in lib/Math/PlanePath/Foo.pm files have
# code exercising them in one of the xt/oeis/*-oeis.t scripts.
#
# Check that A-numbers are not duplicated among the .pm files, since that's
# often a cut-and-paste mistake.
#
# Check that A-numbers are not duplicated among xt/oeis/*-oeis.t scripts,
# since normally only need to exercise a claimed path sequence once.  Except
# often that's not true since the same sequence can arise in separate ways.
# But for now demand duplication is explicitly listed here.
#


use 5.005;
use strict;
use FindBin;
use ExtUtils::Manifest;
use File::Spec;
use File::Slurp;
use Test::More;
use List::MoreUtils;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
# use Smart::Comments;


# new in 5.6, so unless got it separately with 5.005
plan tests => 1;

my $toplevel_dir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
my $manifest_file = File::Spec->catfile ($toplevel_dir, 'MANIFEST');
my $manifest = ExtUtils::Manifest::maniread ($manifest_file);
my $bad = 0;


my $RE_OEIS_anum = qr/A\d{6,7}/;


#------------------------------------------------------------------------------

my %path_seq_anums;
require 'lib/Math/NumSeq/OEIS/Catalogue/Plugin/PlanePathToothpick.pm';
my $aref = Math::NumSeq::OEIS::Catalogue::Plugin::PlanePathToothpick->info_arrayref;
foreach my $info (@$aref) {
  my $anum = $info->{'anum'};
  my %parameters = @{$info->{'parameters'}};
  my $planepath = $parameters{'planepath'}
    || die "Oops, no planepath parameter";
  my ($path_name, @path_args) = split /,/, $planepath;
  push @{$path_seq_anums{$path_name}}, $anum;
}
foreach (values %path_seq_anums) {
  $_ = [  List::MoreUtils::uniq(@$_) ];
}

#------------------------------------------------------------------------------

my @module_filenames
  = grep {m{^lib/Math/PlanePath/[^/]+\.pm$}} keys %$manifest;
@module_filenames = sort @module_filenames;
diag "module count ",scalar(@module_filenames);
my @path_names = map {m{([^/]+)\.pm$}
                        or die "Oops, unmatched module filename $_";
                      $1} @module_filenames;

sub path_pod_anums {
  my ($path_name) = @_;
  my $filename = "lib/Math/PlanePath/$path_name.pm";
  open my $fh, '<', $filename
    or die "Oops, cannot open module filename $filename";
  my @ret;
  while (<$fh>) {
    if (/^ +($RE_OEIS_anum)/) {
      push @ret, $1;
    }
  }
  return @ret;
}

sub path_checked_anums {
  my ($path_name) = @_;
  return (path_xt_anums ($path_name),
          @{$path_seq_anums{$path_name} || []});
}
sub path_xt_anums {
  my ($path_name) = @_;
  my @ret;
  if (open my $fh, '<', "xt/oeis/$path_name-oeis.t") {
    while (<$fh>) {
      if (/^[^#]*\$anum = '($RE_OEIS_anum)'/mg) {
        push @ret, $1;
      }
      if (/^[^#]*anum => '($RE_OEIS_anum)'/mg) {
        push @ret, $1;
      }
    }
  }
  return @ret;
}

sub str_duplicates {
  my %seen;
  return map {$seen{$_}++ == 1 ? ($_) : ()} @_;
}

foreach my $path_name (@path_names) {
  my @pod_anums = path_pod_anums ($path_name);
  my @checked_anums = path_checked_anums ($path_name);

  my %pod_anums = map {$_=>1} @pod_anums;
  my %checked_anums = map {$_=>1} @checked_anums;

  foreach my $anum (str_duplicates(@pod_anums)) {
    diag "Math::PlanePath::$path_name duplicate pod $anum";
  }
  @pod_anums = List::MoreUtils::uniq(@pod_anums);

  foreach my $anum (str_duplicates(@checked_anums)) {
    next if $anum eq 'A000012'; # all ones
    next if $anum eq 'A000027'; # 1,2,3 naturals
    next if $anum eq 'A005408'; # odd 2n+1
    diag "Math::PlanePath::$path_name duplicate check $anum";
  }
  @checked_anums = List::MoreUtils::uniq(@checked_anums);
  diag "";

  foreach my $anum (@pod_anums) {
    if (! exists $checked_anums{$anum}) {
      diag "Math::PlanePath::$path_name pod anum $anum not checked";
    }
  }

  foreach my $anum (@checked_anums) {
    next if $anum eq 'A000004'; # all zeros
    next if $anum eq 'A000012'; # all ones
    next if $anum eq 'A001477'; # integers 0,1,2,3
    next if $anum eq 'A001489'; # negative integers 0,-1,-2,-3
    next if $anum eq 'A081274'; # oeis duplicate
    next if $anum eq 'A000035'; # 0,1 reps
    next if $anum eq 'A059841'; # 1,0 reps
    next if $anum eq 'A165211'; # 0,1,0,1, 1,0,1,0, repeating
    if (! exists $pod_anums{$anum}) {
      diag "Math::PlanePath::$path_name checked anum $anum not in pod";
    }
  }
}
is ($bad, 0);

#------------------------------------------------------------------------------

exit 0;
