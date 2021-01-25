#!/usr/bin/perl -w

# Copyright 2012, 2013, 2015, 2020, 2021 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# Check that OEIS A-numbers listed in lib/Math/PlanePath/Foo.pm files have
# code exercising them in one of the xt/oeis/*-oeis.t scripts.
#
# Check that A-numbers are not duplicated among the .pm files, since that's
# often a cut-and-paste mistake.
#
# Check that A-numbers are not duplicated within an xt/oeis/*-oeis.t script,
# since normally only need to exercise a claimed path sequence once.  Except
# often that's not true since the same sequence can arise in separate ways.
# But for now demand duplication is either disguised there or explicitly
# listed here.
#


use 5.005;
use strict;
use FindBin;
use ExtUtils::Manifest;
use File::Spec;
use File::Slurp;
use Test::More;  # new in 5.6, so unless got it separately with 5.005
use List::Util 'uniqstr';

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

plan tests => 1;

my $toplevel_dir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
my $manifest_filename = File::Spec->catfile ($toplevel_dir, 'MANIFEST');
my $manifest = ExtUtils::Manifest::maniread ($manifest_filename);
my $bad = 0;

my $anum_re = qr/A\d{6,7}/;


my %allow_POD_duplicates
  = (Corner => {A000290 => 1, # with different wider
                A002378 => 1, # with different wider
                A005563 => 1, # with different wider
                A014206 => 1, # with different wider
                A028552 => 1, # with different wider
               },
     DiamondSpiral => {A001105 => 1,  # different n_start
                      },
     CornerReplicate => {A139351 => 1,  # in text and seq list
                        },
     CoprimeColumns => {A002088 => 1,  # different n_start
                       },
     TerdragonCurve => {A057083 => 1,  # two uses
                       },
     AlternatePaper => {A062880 => 1,  # arms=1 and arms=2
                       },
    );

my %allow_checked_not_in_POD
  = (Corner => {A000007 => 1,  # left turn 1 at N=0 only
                A063524 => 1,  # left turn 1 at N=1 only
                A185012 => 1,  # left turn 1 at N=2 only
               },
     TriangleSpiralSkewed => {A081274 => 1,  # duplicate of A038764
                             },
     DragonCurve => {A059841 => 1,  # 1,0 repeating not interesting
                     A000035 => 1,  # 0,1 repeating
                    },
     DiagonalRationals => {A060837 => 1,  # checked in FactorRationals-oeis.t
                          },
    );


#------------------------------------------------------------------------------

# Entries like 'ZOrderCurve' => [ 'A000001', 'A000002', ... ]
my %path_seq_anums;
foreach my $seq_filename ('lib/Math/NumSeq/PlanePathCoord.pm',
                          'lib/Math/NumSeq/PlanePathN.pm',
                          'lib/Math/NumSeq/PlanePathDelta.pm',
                          'lib/Math/NumSeq/PlanePathTurn.pm',
                         ) {
  open my $fh, '<', $seq_filename or die "Cannot open $seq_filename";
  while (<$fh>) {
    if (/^\s*# OEIS-(Catalogue|Other):\s+($anum_re)([^#]+)/) {
      my $anum = $2;
      my @args = split /\s/, $3;
      my %args = map { split /=/, $_, 2 } @args;
      ### %args
      my $planepath_and_args = $args{'planepath'} || die "Oops, no planepath parameter";
      my ($planepath, @planepath_args) = split /,/, $planepath_and_args;
      push @{$path_seq_anums{$planepath}}, $anum;
    }
  }
}
foreach (values %path_seq_anums) {
  @$_ = uniqstr(@$_);
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
  my ($planepath_name) = @_;
  my $filename = "lib/Math/PlanePath/$planepath_name.pm";
  open my $fh, '<', $filename
    or die "Oops, cannot open module filename $filename";
  my @ret;
  while (<$fh>) {
    if (/^ +($anum_re)/) {
      push @ret, $1;
    }
  }
  return @ret;
}

sub path_checked_anums {
  my ($planepath_name) = @_;
  return (path_xt_anums ($planepath_name),
          @{$path_seq_anums{$planepath_name} || []});
}
sub path_xt_anums {
  my ($planepath_name) = @_;
  my @ret;
  my %seen;
  foreach my $filename (File::Spec->catfile('xt','oeis',"$planepath_name-oeis.t"),
                        File::Spec->catfile('xt',"$planepath_name-hog.t")) {
    open my $fh, '<', $filename or next;
    while (<$fh>) {
      my $anum;
      # if (/^[^#]*\$anum = '($anum_re)'/mg) {
      if (/^[^#]*'($anum_re)'/mg) {
        $anum = $1;
      } elsif (/^[^#]*anum => '($anum_re)'/mg) {
        $anum = $1;
      } else {
        next;
      }
      push @ret, $anum;
      if ($seen{$anum}) {
        print "$filename:$.: duplicate check, previous at line $seen{$anum}\n";
        print "$filename:$seen{$anum}: ... previous here\n";
      } else {
        $seen{$anum} = $.;
      }
    }
  }
  return @ret;
}

# From among the argument strings, return those which appear more than once.
sub str_duplicates {
  my %seen;
  return map {$seen{$_}++ == 1 ? ($_) : ()} @_;
}

foreach my $planepath_name (@path_names) {
  my @pod_anums = path_pod_anums ($planepath_name);
  my @checked_anums = path_checked_anums ($planepath_name);

  my %pod_anums = map {$_=>1} @pod_anums;
  my %checked_anums = map {$_=>1} @checked_anums;

  foreach my $anum (str_duplicates(@pod_anums)) {
    next if $allow_POD_duplicates{$planepath_name}->{$anum};
    diag "Math::PlanePath::$planepath_name $anum duplicated within POD";
  }
  @pod_anums = uniqstr(@pod_anums);

  foreach my $anum (str_duplicates(@checked_anums)) {
    next if $anum eq 'A000012'; # all ones
    next if $anum eq 'A000027'; # 1,2,3 naturals
    next if $anum eq 'A005408'; # odd 2n+1
    diag "Math::PlanePath::$planepath_name $anum checked and also catalogued";
  }
  @checked_anums = uniqstr(@checked_anums);
  diag "";

  foreach my $anum (@pod_anums) {
    next if $anum eq 'A191689'; # CCurve fractal dimension
    if (! exists $checked_anums{$anum}) {
      diag "Math::PlanePath::$planepath_name $anum in POD, not checked";
    }
  }

  foreach my $anum (@checked_anums) {
    next if $anum eq 'A000004'; # all zeros
    next if $anum eq 'A000012'; # all ones
    next if $anum eq 'A001477'; # integers 0,1,2,3
    next if $anum eq 'A001489'; # negative integers 0,-1,-2,-3
    next if $anum eq 'A000035'; # 0,1 reps
    next if $anum eq 'A059841'; # 1,0 reps
    next if $allow_checked_not_in_POD{$planepath_name}->{$anum};
    if (! exists $pod_anums{$anum}) {
      diag "Math::PlanePath::$planepath_name $anum checked, not in POD";
    }
  }
}
is ($bad, 0);

#------------------------------------------------------------------------------

exit 0;
