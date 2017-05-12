#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Math-NumSeq-Alpha.
#
# Math-NumSeq-Alpha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq-Alpha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq-Alpha.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
plan tests => 1;

use lib 't','xt', 'devel/lib';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

# uncomment this to run the ### lines
#use Smart::Comments '###';

use POSIX ();
use constant DBL_INT_MAX => (POSIX::FLT_RADIX() ** POSIX::DBL_MANT_DIG());
use constant MY_MAX => (POSIX::FLT_RADIX() ** (POSIX::DBL_MANT_DIG()-5));

sub diff_nums {
  my ($gotaref, $wantaref) = @_;
  my $diff;
  for (my $i = 0; $i < @$gotaref; $i++) {
    if ($i > @$wantaref) {
      return "want ends prematurely pos=$i";
    }
    my $got = $gotaref->[$i];
    my $want = $wantaref->[$i];
    if (! defined $got && ! defined $want) {
      next;
    }
    if (! defined $got || ! defined $want) {
      return "different pos=$i got=".(defined $got ? $got : '[undef]')
        ." want=".(defined $want ? $want : '[undef]');
    }
    $got =~ /^[0-9.-]+$/
      or return "not a number pos=$i got='$got'";
    $want =~ /^[0-9.-]+$/
      or return "not a number pos=$i want='$want'";
    if ($got != $want) {
      MyTestHelpers::diag ("different pos=$i numbers got=$got want=$want");
      $diff ||= "different pos=$i numbers got=$got want=$want";
    }
  }
  return $diff;
}

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
                      A033307 => 'A007376',
                     );

#------------------------------------------------------------------------------
my $good = 1;
my $total_checks = 0;

sub check_class {
  my ($anum, $class, $parameters) = @_;
  ### check_class() ...
  ### $class
  ### $parameters

  # return unless $class =~ /Sto/;
  # return unless $class =~ /PrimeF/;
  # return unless $class =~ /DigitP/;
  # return unless $class =~ /DigitCount/;
  # return unless $class =~ /Plain/;
  # return unless $class =~ /Alpha/;
  # return unless $class =~ /Spiro/;
  # return unless $class =~ /Cbrt/;
  # return unless $class =~ /Slop/;
  # return unless $class =~ /Kap/;
  # return unless $class =~ /Sieve/;
  # return unless $class =~ /HypotC/;
  # return unless $class =~ /Loe/;
  # return unless $class =~ /DigitP/;
  # return unless $class =~ /Kap/;
  # return unless $class =~ /Pier/;
  # return unless $class =~ /FactorialP/;
  # return unless $class =~ /Pisano/;
  # return unless $class =~ /FibonacciFreq/;
  # return unless $class =~ /RadixConv/;
  # return unless $anum eq 'A095810';

  eval "require $class" or die;

  my $name = join(',',
                  $class,
                  map {defined $_ ? $_ : '[undef]'} @$parameters);
  MyTestHelpers::diag ("$anum $name");

  my $max_value = undef;
  my $max_count = undef;
  if ($class eq 'Math::NumSeq::Factorials'
      || $class eq 'Math::NumSeq::Primorials'
      || $class eq 'Math::NumSeq::RadixConversion'
     ) {
    $max_value = 'unlimited';

  } elsif ($anum eq 'A007700'
           || $anum eq 'A023272'
           || $anum eq 'A023302'
           || $anum eq 'A023330') {
    # Cunningham
    $max_value = 100_000;

  } elsif ($anum eq 'A005109') { # Pierpont
    $max_value = 1_000_000;

  } elsif ($anum eq 'A006886') {  # Kaprekar
    $max_value = 100_000;

  } elsif ($class =~ /FactorialProducts/) {
    $max_value = 100_000;

  } elsif ($class =~ /FibonacciProducts/) {
    $max_value = 10000; # bit slow yet

  } elsif ($anum eq 'A005384') {
    # Sophie Germain / Cunningham, shorten for now
    $max_value = 1_000_000;
  }

  my ($want, $want_i_start, $filename) = MyOEIS::read_values
    ($anum,
     max_value => $max_value,
     max_count => $max_count)
      or do {
        MyTestHelpers::diag("skip $anum $name, no file data");
        return;
      };
  ### read_values len: scalar(@$want)
  ### $want_i_start


  if ($anum eq 'A057696') { # pt_BR lengths
    $want_i_start = 1;
  }


  my $want_count = scalar(@$want);
  return unless @$want;

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
      MyTestHelpers::diag ("got anum  $got_anum");
      MyTestHelpers::diag (ref $seq);
    }
  }

  {
    my $got_i_start = $seq->i_start;
    if ($got_i_start != $want_i_start
        && $anum ne 'A000004' # offset=0, but allow other i_start here
        && $anum ne 'A000012' # offset=0, but allow other i_start here
       ) {
      $good = 0;
      MyTestHelpers::diag ("bad: $name");
      MyTestHelpers::diag ("got  i_start  $got_i_start");
      MyTestHelpers::diag ("want i_start  $want_i_start");
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

    my $diff = diff_nums($got, $want);
    if (defined $diff) {
      $good = 0;
      MyTestHelpers::diag ("bad: $name by next() hi=$hi");
      MyTestHelpers::diag ($diff);
      MyTestHelpers::diag (ref $seq);
      MyTestHelpers::diag ($filename);
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

    my $diff = diff_nums($got, $want);
    if (defined $diff) {
      $good = 0;
      MyTestHelpers::diag ("bad: $name by rewind next() hi=$hi");
      MyTestHelpers::diag ($diff);
      MyTestHelpers::diag (ref $seq);
      MyTestHelpers::diag ($filename);
      MyTestHelpers::diag ("got  len ".scalar(@$got));
      MyTestHelpers::diag ("want len ".scalar(@$want));
      if ($#$got > 200) { $#$got = 200 }
      if ($#$want > 200) { $#$want = 200 }
      MyTestHelpers::diag ("got  ". join(',', map {defined() ? $_ : 'undef'} @$got));
      MyTestHelpers::diag ("want ". join(',', map {defined() ? $_ : 'undef'} @$want));
    }
  }

  {
    ### by ith() ...
    $seq->can('ith')
      or next;

    my $i = $seq->i_start;
    if (($max_value||'') eq 'unlimited') {
      $i = Math::NumSeq::_to_bigint($i);
    }

    my @got;
    while (@got < @$want) {
      my $value = $seq->ith($i++);
      last if (! defined $value);
      push @got, $value;
    }
    my $got = \@got;
    ### $got

    my $diff = diff_nums($got, $want);
    if (defined $diff) {
      $good = 0;
      MyTestHelpers::diag ("bad: $name by ith()");
      MyTestHelpers::diag ($diff);
      MyTestHelpers::diag (ref $seq);
      MyTestHelpers::diag ($filename);
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
      if (defined $values_min
          && defined $data_min
          && $values_min != $data_min) {
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

    my $diff = diff_nums($got, $want);
    if (defined $diff) {
      $good = 0;
      MyTestHelpers::diag ("bad: $name by pred() hi=$hi");
      MyTestHelpers::diag ($diff);
      MyTestHelpers::diag (ref $seq);
      MyTestHelpers::diag ($filename);
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
# forced

# check_class ('A001097',
#              'Math::NumSeq::TwinPrimes',
#              [ pairs => 'both' ]);
# exit 0;


#------------------------------------------------------------------------------
# OEIS-Catalogue generated vs files

# use File::Path;
# File::Path::make_path('lib/Math/NumSeq/OEIS/Catalogue/Plugin/');
# system("cd devel && perl ../tools/make-oeis-catalogue.pl --module=TempDevel --other=both") == 0
#   or die;
# require 'devel/lib/Math/NumSeq/OEIS/Catalogue/Plugin/TempDevel.pm';
# unlink  'devel/lib/Math/NumSeq/OEIS/Catalogue/Plugin/TempDevel.pm' or die;
# # rmdir  'devel/lib/Math/NumSeq/OEIS/Catalogue/Plugin' or die;
# # rmdir  'devel/lib/Math/NumSeq/OEIS/Catalogue' or die;
# # rmdir  'devel/lib/Math/NumSeq/OEIS' or die;
# my $aref = Math::NumSeq::OEIS::Catalogue::Plugin::TempDevel::info_arrayref();

require Math::NumSeq::OEIS::Catalogue::Plugin::Alpha;
my $aref = Math::NumSeq::OEIS::Catalogue::Plugin::Alpha::info_arrayref();

foreach my $info (@$aref) {
  ### $info
  check_class ($info->{'anum'},
               $info->{'class'},
               $info->{'parameters'});
}

MyTestHelpers::diag ("total checks $total_checks");
ok ($good);
exit 0;
