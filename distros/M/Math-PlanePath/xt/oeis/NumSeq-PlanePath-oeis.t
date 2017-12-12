#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# Check PlanePathCoord etc sequences against OEIS data.
#


use 5.004;
use strict;
use File::Spec;
use Test;
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

# uncomment this to run the ### lines
# use Smart::Comments '###';


sub want_anum {
  my ($anum) = @_;
  # return 0 unless $anum =~ /A246960/;
  # return 0 unless $anum =~ /A151922|A183060/;
  # return 0 unless $anum =~ /A177702|A102283|A131756/;
  return 1;
}
sub want_planepath {
  my ($planepath) = @_;
  # return 0 unless $planepath =~ /ComplexPlus/;
  # return 0 unless $planepath =~ /Flowsnake/;
  # return 0 unless $planepath =~ /Octag|Pent|Hept/;
  # return 0 unless $planepath =~ /Divis|DiagonalRationals|CoprimeCol/;
  # return 0 unless $planepath =~ /DiamondSpiral/;
  # return 0 unless $planepath =~ /Coprime/;
  # return 0 unless $planepath =~ /LCorn|RationalsTree/;
  # return 0 unless $planepath =~ /^Corner$/i;
  # return 0 unless $planepath =~ /SierpinskiArrowheadC/;
  # return 0 unless $planepath =~ /TriangleSpiralSkewed/;
  # return 0 unless $planepath =~ /^Rows/;
  # return 0 unless $planepath =~ /DiagonalRationals/;
  return 1;
}
sub want_coordinate {
  my ($type) = @_;
  # return 0 unless $type =~ /BitXor/;
  # return 0 unless $type =~ /^Abs[XY]/;
  # return 0 unless $type =~ /DiffYX/i;
  # return 0 unless $type =~ /ExperimentalPairsYX/;
  # return 0 unless $type =~ /SLR|SRL|LSR/;
  return 1;
}

#------------------------------------------------------------------------------
# use POSIX ();
# use constant DBL_INT_MAX => (POSIX::FLT_RADIX() ** POSIX::DBL_MANT_DIG());
# use constant MY_MAX => (POSIX::FLT_RADIX() ** (POSIX::DBL_MANT_DIG()-5));

sub _delete_duplicates {
  my ($arrayref) = @_;
  my %seen;
  @seen{@$arrayref} = ();
  @$arrayref = sort {$a<=>$b} keys %seen;
}

sub _min {
  my $ret = shift;
  while (@_) {
    my $next = shift;
    if ($ret > $next) {
      $ret = $next;
    }
  }
  return $ret;
}
sub _max {
  my $ret = shift;
  while (@_) {
    my $next = shift;
    if ($next > $ret) {
      $ret = $next;
    }
  }
  return $ret;
}

my %duplicate_anum = (A021015 => 'A010680',
                      A081274 => 'A038764',
                     );

#------------------------------------------------------------------------------
my $good = 1;
my $total_checks = 0;

sub check_class {
  my ($anum, $class, $parameters) = @_;
  ### check_class() ...
  ### $class
  ### $parameters

  my %parameters = @$parameters;
  # return unless $class =~ /PlanePathTurn/;
  # return unless $parameters{'planepath'} =~ /DiagonalRat/i;
  # return unless $parameters{'planepath'} =~ /AlternateP/;
  # return unless $parameters{'planepath'} =~ /Peano/;
  # return unless $parameters{'planepath'} =~ /PyramidRows/;
  # return unless $parameters{'planepath'} =~ /Fib/;
  # return unless $parameters{'planepath'} =~ /TriangleSpiralSkewed/;

  return unless want_anum($anum);
  return unless want_planepath($parameters{'planepath'}
                               || '');
  return unless want_coordinate($parameters{'coordinate_type'}
                                || $parameters{'delta_type'}
                                || $parameters{'line_type'}
                                || $parameters{'turn_type'}
                                || '');

  eval "require $class" or die;

  my $name = join(',',
                  $class,
                  map {defined $_ ? $_ : '[undef]'} @$parameters);

  my $max_count = undef;
  if ($anum eq 'A038567'
      || $anum eq 'A038566'
      || $anum eq 'A020652'
      || $anum eq 'A020653') {
    # CoprimeColumns, DiagonalRationals  shortened for now
    $max_count = 10000;

  } elsif ($anum eq 'A051132') {
    # Hypot
    $max_count = 1000;
  } elsif ($anum eq 'A173027') {
    # WythoffPreiminaryTriangle
    $max_count = 3000;
  }

  my ($want, $want_i_start) = MyOEIS::read_values ($anum,
                                                   max_count => $max_count)
    or do {
      MyTestHelpers::diag("skip $anum $name, no file data");
      return;
    };
  ### read_values len: scalar(@$want)
  ### $want_i_start

  if ($anum eq 'A009003') {
    #  PythagoreanHypots slow, only first 250 values for now ...
    splice @$want, 250;
  } elsif ($anum eq 'A003434') {
    #  TotientSteps slow, only first 250 values for now ...
    splice @$want, 250;
  } elsif ($anum eq 'A005408') { # odd numbers
    #  shorten for CellularRule rule=84 etc
    splice @$want, 500;

  }

  my $want_count = scalar(@$want);
  MyTestHelpers::diag ("$anum $name  ($want_count values to $want->[-1])");

  my $hi = $want->[-1];
  if ($hi < @$want) {
    $hi = @$want;
  }
  ### $hi
  # hi => $hi

  my $seq = $class->new (@$parameters);
  ### seq class: ref $seq
  if ($seq->isa('Math::NumSeq::OEIS::File')) {
    die "Oops, not meant to exercies $seq";
  }

  {
    ### $seq
    my $got_anum = $seq->oeis_anum;
    if (! defined $got_anum) {
      $got_anum = 'undef';
    }
    my $want_anum = $duplicate_anum{$anum} || $anum;
    if ($got_anum ne $want_anum) {
      $good = 0;
      MyTestHelpers::diag ("bad: $name");
      MyTestHelpers::diag ("got  anum $got_anum");
      MyTestHelpers::diag ("want anum $want_anum");
      MyTestHelpers::diag (ref $seq);
    }
  }

  {
    my $got_i_start = $seq->i_start;
    if (! defined $want_i_start) {
      MyTestHelpers::diag ("skip i_start check: \"stripped\" values only");

    } elsif ($got_i_start != $want_i_start
             && $anum ne 'A000004' # offset=0, but allow other i_start here
             && $anum ne 'A000012' # offset=0, but allow other i_start here
            ) {
      $good = 0;
      MyTestHelpers::diag ("bad: $name");
      MyTestHelpers::diag ("got  i_start  ",$got_i_start);
      MyTestHelpers::diag ("want i_start  ",$want_i_start);
    }
  }

  {
    ### by next() ...
    my @got;
    my $got = \@got;
    while (my ($i, $value) = $seq->next) {
      push @got, $value;
      if (@got >= @$want) {
        last;
      }
    }

    my $diff = MyOEIS::diff_nums($got, $want);
    if (defined $diff) {
      $good = 0;
      MyTestHelpers::diag ("bad: $name by next() hi=$hi");
      MyTestHelpers::diag ($diff);
      MyTestHelpers::diag (ref $seq);
      MyTestHelpers::diag ("got  len ".scalar(@$got));
      MyTestHelpers::diag ("want len ".scalar(@$want));
      if ($#$got > 200) { $#$got = 200 }
      if ($#$want > 200) { $#$want = 200 }
      MyTestHelpers::diag ("got  ". join(',', map {defined() ? $_ : 'undef'} @$got));
      MyTestHelpers::diag ("want ". join(',', map {defined() ? $_ : 'undef'} @$want));
    }
  }
  {
    ### by next() after rewind ...
    $seq->rewind;

    my @got;
    my $got = \@got;
    while (my ($i, $value) = $seq->next) {
      # ### $i
      # ### $value
      push @got, $value;
      if (@got >= @$want) {
        last;
      }
    }

    my $diff = MyOEIS::diff_nums($got, $want);
    if (defined $diff) {
      $good = 0;
      MyTestHelpers::diag ("bad: $name by rewind next() hi=$hi");
      MyTestHelpers::diag ($diff);
      MyTestHelpers::diag (ref $seq);
      MyTestHelpers::diag ("got  len ".scalar(@$got));
      MyTestHelpers::diag ("want len ".scalar(@$want));
      if ($#$got > 200) { $#$got = 200 }
      if ($#$want > 200) { $#$want = 200 }
      MyTestHelpers::diag ("got  ". join(',', map {defined() ? $_ : 'undef'} @$got));
      MyTestHelpers::diag ("want ". join(',', map {defined() ? $_ : 'undef'} @$want));
    }
  }

  {
    ### by pred() ...
    $seq->can('pred')
      or next;
    if ($seq->characteristic('count')) {
      ### no pred on characteristic(count) ..
      next;
    }
    if (! $seq->characteristic('increasing')) {
      ### no pred on not characteristic(increasing) ..
      next;
    }
    if ($seq->characteristic('digits')) {
      ### no pred on characteristic(digits) ..
      next;
    }
    if ($seq->characteristic('modulus')) {
      ### no pred on characteristic(modulus) ..
      next;
    }
    if ($seq->characteristic('pn1')) {
      ### no pred on characteristic(pn1) ..
      next;
    }

    $hi = 0;
    foreach my $want (@$want) {
      if ($want > $hi) { $hi = $want }
    }
    if ($hi > 1000) {
      $hi = 1000;
      $want = [ grep {$_<=$hi} @$want ];
    }
    _delete_duplicates($want);
    #### $want

    my @got;
    foreach my $value (_min(@$want) .. $hi) {
      #### $value
      if ($seq->pred($value)) {
        push @got, $value;
      }
    }
    my $got = \@got;

    my $diff = MyOEIS::diff_nums($got, $want);
    if (defined $diff) {
      $good = 0;
      MyTestHelpers::diag ("bad: $name by pred() hi=$hi");
      MyTestHelpers::diag ($diff);
      MyTestHelpers::diag (ref $seq);
      MyTestHelpers::diag ("got  len ".scalar(@$got));
      MyTestHelpers::diag ("want len ".scalar(@$want));
      if ($#$got > 200) { $#$got = 200 }
      if ($#$want > 200) { $#$want = 200 }
      MyTestHelpers::diag ("got  ". join(',', map {defined() ? $_ : 'undef'} @$got));
      MyTestHelpers::diag ("want ". join(',', map {defined() ? $_ : 'undef'} @$want));
    }

    {
      my $data_min = _min(@$want);
      my $values_min = $seq->values_min;
      if (defined $values_min && $values_min != $data_min) {
        $good = 0;
        MyTestHelpers::diag ("bad: $name values_min $values_min but data min $data_min");
      }
    }
    {
      my $data_max = _max(@$want);
      my $values_max = $seq->values_max;
      if (defined $values_max && $values_max != $data_max) {
        $good = 0;
        MyTestHelpers::diag ("bad: $name values_max $values_max not seen in data, only $data_max");
      }
    }
  }

  $total_checks++;
}

#------------------------------------------------------------------------------
# extras

# check_class ('A059906', # ZOrderCurve second bit
#              'Math::NumSeq::PlanePathCoord',
#              [ planepath => 'CornerReplicate',
#                coordinate_type => 'Y' ]);

# exit 0;


#------------------------------------------------------------------------------
# OEIS-Other vs files

MyTestHelpers::diag ("\"Other\" uncatalogued sequences:");
{
  system("perl ../ns/tools/make-oeis-catalogue.pl --module=TempOther --other=only") == 0
    or die;
  my $filename = File::Spec->rel2abs('lib/Math/NumSeq/OEIS/Catalogue/Plugin/TempOther.pm');
  require $filename;
  unlink  $filename or die "cannot unlink $filename: $!";

  my $aref = Math::NumSeq::OEIS::Catalogue::Plugin::TempOther::info_arrayref();
  foreach my $info (@$aref) {
    ### $info
    check_class ($info->{'anum'},
                 $info->{'class'},
                 $info->{'parameters'});
  }
  MyTestHelpers::diag ("");
}

#------------------------------------------------------------------------------
# OEIS-Catalogue generated vs files

MyTestHelpers::diag ("Catalogue sequences:");
{
  require Math::NumSeq::OEIS::Catalogue::Plugin::PlanePath;
  my $aref = Math::NumSeq::OEIS::Catalogue::Plugin::PlanePath->info_arrayref();

  {
    require Math::NumSeq::OEIS::Catalogue::Plugin::PlanePathToothpick;
    my $aref2 = Math::NumSeq::OEIS::Catalogue::Plugin::PlanePathToothpick->info_arrayref();
    $aref = [ @$aref, @$aref2 ];
  }
  MyTestHelpers::diag ("total catalogue entries ",scalar(@$aref));

  foreach my $info (@$aref) {
    ### $info
    check_class ($info->{'anum'},
                 $info->{'class'},
                 $info->{'parameters'});
  }
}

MyTestHelpers::diag ("total checks $total_checks");
ok ($good);

exit 0;
