#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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


# Compare NumSeq code against downloaded OEIS values.
#


use 5.004;
use strict;
use Test;
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::OEIS::Catalogue;

eval "use Math::BigInt try => 'GMP'; 1"  # pure perl too slow for big sqrts
  || eval "use Math::BigInt; 1"
  || die;

use POSIX ();
POSIX::setlocale(POSIX::LC_ALL(), 'C'); # no message translations

# uncomment this to run the ### lines
#use Smart::Comments '###';


use constant DBL_INT_MAX => (POSIX::FLT_RADIX() ** POSIX::DBL_MANT_DIG());
use constant MY_MAX => (POSIX::FLT_RADIX() ** (POSIX::DBL_MANT_DIG()-5));

sub diff_nums {
  my ($gotaref, $wantaref) = @_;
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
      return ("different pos=$i def/undef"
              . "\n  got=".(defined $got ? $got : '[undef]')
              . "\n want=".(defined $want ? $want : '[undef]'));
    }
    $got =~ /^[0-9.-]+$/
      or return "not a number pos=$i got='$got'";
    $want =~ /^[0-9.-]+$/
      or return "not a number pos=$i want='$want'";
    if ($got ne $want) {
      ### $got
      ### $want
      return ("different pos=$i numbers"
              . "\n  got=".(defined $got ? $got : '[undef]')
              . "\n want=".(defined $want ? $want : '[undef]'));
    }
  }
  return undef;
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
                     );

#------------------------------------------------------------------------------
my $good = 1;
my $total_checks = 0;

sub check_class {
  my ($anum, $class, $parameters) = @_;
  ### check_class() ...
  ### $class
  ### $parameters

  return if $class eq 'Math::NumSeq::PlanePathCoord' # tested in its own dist
    || $class eq 'Math::NumSeq::PlanePathDelta'
      || $class eq 'Math::NumSeq::PlanePathTurn'
        || $class eq 'Math::NumSeq::PlanePathN';


  # skip all except ...
  #
  # return unless $class =~ /Liouv/;
  # return unless $class =~ /PrimeIndex/;
  # return unless $class =~ /Golomb/;
  # return unless $class =~ /Runs/;
  # return unless $class =~ /FactorCount/;
  # return unless $class =~ /Cbrt/;
  # return unless $class =~ /Star/;
  # return unless $class =~ /Luc|Fib|Cullen|Wood/;
  # return unless $class =~ /Lucas/;
  # return unless $class =~ /RadixWithout/;
  # return unless $class =~ /Duf/;
  # return unless $class =~ /SqrtD/;
  # return unless $class =~ /Power/;
  # return unless $class =~ /Repdigit/;
  # return unless $class =~ /PowerF/;
  # return unless $class =~ /PrimesD/;
  # return unless $class =~ /Golay/;
  # return unless $class =~ /Bal/;
  # return unless $anum eq 'A000108';

  eval "require $class" or die;

  my $name = join(',',
                  $class,
                  map {defined $_ ? $_ : '[undef]'} @$parameters);

  MyTestHelpers::diag ("$anum $name");

  my $max_value = ~0 >> 8;   # avoid rounding
  if ($max_value > 2**45) {
    $max_value = (1 << 45) - 1;
  }
  my $max_count = undef;
  if ($class eq 'Math::NumSeq::Factorials'
      || $class eq 'Math::NumSeq::Primorials'
      || $class eq 'Math::NumSeq::Fibonacci'
      || $class eq 'Math::NumSeq::Pell'
      || $class eq 'Math::NumSeq::LucasNumbers'
      || $class eq 'Math::NumSeq::Catalan'
      || $class eq 'Math::NumSeq::Perrin'
      || $class eq 'Math::NumSeq::Squares'
      || $class eq 'Math::NumSeq::Cubes'
      || $class eq 'Math::NumSeq::Tribonacci'
      || $class eq 'Math::NumSeq::ProthNumbers'
      || $class eq 'Math::NumSeq::CullenNumbers'
      || $class eq 'Math::NumSeq::WoodallNumbers'
      || $class eq 'Math::NumSeq::ReverseAdd'
      || $class eq 'Math::NumSeq::RadixConversion'
      || $name eq 'Repdigiits,radix=2'
     ) {
    $max_value = 'unlimited';

  } elsif ($anum eq 'A001477' || $anum eq 'A000027') {
    # integers and naturals
    $max_count = 10000;

  } elsif ($anum eq 'A009003') { # Math::NumSeq::PythagoreanHypots slow
    $max_count = 250;

  } elsif ($anum eq 'A003434') { # Math::NumSeq::TotientSteps slow
    $max_count = 250;

  } elsif ($anum eq 'A007770') {
    # Math::NumSeq::Happy bit slow, not B-file 140,000 ...
    $max_count = 20000;

  } elsif ($anum eq 'A002945'   # CbrtContinued
           || $anum eq 'A002946'
           || $anum eq 'A010239') {
    $max_count = 400;

  } elsif ($anum eq 'A000959') { # LuckyNumbers
    $max_value = 20_000;

  } elsif ($anum eq 'A082897') {
    # perfect totients
    # full B-file goes to 2^32 which is too much to sieve
    $max_value = 200_000;

  } elsif ($anum eq 'A001359'   # TwinPrimes
           || $anum eq 'A006512'
           || $anum eq 'A014574'
           || $anum eq 'A001097') {
    $max_value = 1_000_000;

  } elsif ($anum eq 'A000040'
           || $anum eq 'A006450'
           || $anum eq 'A049090'
           || $anum eq 'A049203'
           || $anum eq 'A049202'
           || $anum eq 'A057849'
           || $anum eq 'A057850'
           || $anum eq 'A057851'
           || $anum eq 'A057847'
           || $anum eq 'A058332'
           || $anum eq 'A093047'
           || $anum eq 'A093046'
          ) {
    # PrimeIndexPrimes shorten
    $max_value = 1_000_000;

  } elsif ($anum eq 'A002858'
           || $anum eq 'A002859'
           || $anum eq 'A003666'
           || $anum eq 'A003667'
           || $anum eq 'A001857'
           || $anum eq 'A048951'
           || $anum eq 'A007300') {
    # UlamSequence shortened for now
    $max_count = 1000;

  } elsif ($anum eq 'A000004') {
    # shorten anything all zeros
    $max_count = 20;

  } elsif ($anum eq 'A005384') {
    # sophie germain shorten for now
    $max_value = 1_000_000;

  } elsif ($class =~ /AlmostPrimes/) {
    # AlmostPrimes shorten for now
    $max_value = 10_000_000;

  } elsif ($class =~ /ReverseAdd/) {
    # shorten the biggest nums
    # @$want = grep {length($_) < 100} @$want;

  } elsif ($anum eq 'A006567') {
    # emirps shorten for now
    $max_value = 100_000;

  } elsif ($anum eq 'A001694'    # Powerful all power=2
           || $anum eq 'A036966' # Powerful all power=3
           || $anum eq 'A036967' # Powerful all power=4
           || $anum eq 'A069492' # Powerful all power=5
           || $anum eq 'A069493' # Powerful all power=6
          ) {
    # shorten for now
    $max_value = 30_000;

  } elsif (
           $anum eq 'A004558'
           || $anum eq 'A004559'
           || $anum eq 'A004560'
           || $anum eq 'A004561'
           || $anum eq 'A004564'
           || $anum eq 'A004565'
           || $anum eq 'A004566'
           || $anum eq 'A004568'
           || $anum eq 'A004572'
           || $anum eq 'A004573'
           || $anum eq 'A004574'
           || $anum eq 'A004580'
           || $anum eq 'A004581'
           || $anum eq 'A004542' # sqrt(2) in base 5
          ) {
    MyTestHelpers::diag ("trim doubtful end $anum $name");
    $max_count = 50;

  } elsif ($anum eq 'A070197') {
    # final 12 of sqrt(2) base 60 seems bad, trim
    $max_count = 72;
    MyTestHelpers::diag ("trim doubtful end $anum $name");
  } elsif ($anum eq 'A004582') {
    # last few of sample values sqrt(8) base 7 seem bad, trim
    $max_count = 50;
    MyTestHelpers::diag ("trim doubtful end $anum $name");
  } elsif ($anum eq 'A004583') {
    # last digit of sample values octal sqrt(8) seems is 4 think should be 5,
    # trim it off for now
    $max_count = 50;
    MyTestHelpers::diag ("trim doubtful end $anum $name");
  } elsif ($anum eq 'A004584') {
    # last few of sample values sqrt(8) base 9 seem bad, trim
    $max_count = 50;
    MyTestHelpers::diag ("trim doubtful end $anum $name");
  } elsif ($anum eq 'A004588') {
    # last 3,3,0,2,3,4,2,4,1,2,4,4,1 sample values sqrt(10) base 5 seem bad,
    # trim
    $max_count = 50;
    MyTestHelpers::diag ("trim doubtful end $anum $name");
  } elsif ($class =~ /SqrtDigits/) {
    unless (Math::BigInt::GMP->VERSION) { # plain Calc sqrt a bit slow
      $max_count = 1000;
    }
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


  if ($anum eq 'A030547') {
    if ($want->[9] == 2) {
      MyTestHelpers::diag("$anum fixup samples start i=1 but OFFSET=0");
      unshift @$want, 1;
    }
  }




  # skip all except ...
  #
  # return unless $anum eq 'A057696';


  my $want_count = scalar(@$want);
  my $hi = 10;
  if (@$want) {
    $hi = $want->[-1];
    if ($hi < @$want) {
      $hi = @$want;
    }
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
        && $anum ne 'A010171' # SqrtContinued 103
        && $anum ne 'A010172' # SqrtContinued 106
        && $anum ne 'A010173' # SqrtContinued 107
        && $anum ne 'A010174' # SqrtContinued 108
        && $anum ne 'A010175' # SqrtContinued 109
       ) {
      if ($class =~ /RadixWithout/  # FIXME
          || $class =~ /SqrtDigits/ # FIXME
          || $anum eq 'A064150'    # harshad base 3
         ) {
        MyTestHelpers::diag ("todo i_start: got $got_i_start want $want_i_start  $name");
      } else {
        $good = 0;
        MyTestHelpers::diag ("bad: $name");
        MyTestHelpers::diag ("got  i_start  $got_i_start");
        MyTestHelpers::diag ("want i_start  $want_i_start");
      }
    }
  }

  {
    ### by next() ...
    my @got;
    my $got = \@got;
    while (@got < @$want
           && (my ($i, $value) = $seq->next)) {
      push @got, $value;
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
    while (@got < @$want
           && (my ($i, $value) = $seq->next)) {
      push @got, $value;
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

    my $i_start = $seq->i_start;
    my $i = $i_start;
    if (($max_value||'') eq 'unlimited') {
      $i = Math::NumSeq::_to_bigint($i);
    }

    my @got;
    while (@got < @$want) {
      my $value = $seq->ith($i++);
      # ### got: "$i $value, towards want size ".@$want
      last if (! defined $value);
      push @got, $value;
    }
    my $got = \@got;
    # ### $got

    my $diff = diff_nums($got, $want);
    if (defined $diff) {
      $good = 0;
      MyTestHelpers::diag ("bad: $name by ith() from i_start=$i_start");
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
      if ($seq->isa('Math::NumSeq::ReverseAddSteps')) {
        # 196 infinite value -1 not reached
        if ($data_min > -1) {
          $data_min = -1;
        }
      }
      unless ($seq->isa('Math::NumSeq::FractionDigits')) {
        # FractionDigits doesn't have actual values_min yet, only 0 to radix-1

        my $values_min = $seq->values_min;
        if (defined $values_min
            && defined $data_min
            && $values_min != $data_min) {
          $good = 0;
          MyTestHelpers::diag ("bad: $name values_min $values_min but data min $data_min");
        }
      }
    }
    {
      unless ($seq->isa('Math::NumSeq::FractionDigits')) {

        my $values_max = $seq->values_max;
        if (defined $values_max) {
          my $data_max = _max(@$want);
          if ($values_max != $data_max) {
            # $good = 0;
            MyTestHelpers::diag ("bad: $name values_max=$values_max not seen in data, only $data_max");
          }
        }
      }
    }
  }

  {
    ### by pred() ...
    $seq->can('pred')
      or next;
    if ($seq->characteristic('count')) {
      ### no pred on characteristic(count) ...
      next;
    }
    if (! $seq->characteristic('increasing')) {
      ### no pred on not characteristic(increasing) ...
      next;
    }
    if ($seq->characteristic('digits')) {
      ### no pred on characteristic(digits) ...
      next;
    }
    if ($seq->characteristic('modulus')) {
      ### no pred on characteristic(modulus) ...
      next;
    }
    if ($seq->characteristic('pn1')) {
      ### no pred on characteristic(pn1) ...
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
    ### $hi
    ### $want

    my @got;
    my $lo = _min(@$want);
    if (! defined $lo && $seq->can('ith')) {
      $lo = $seq->ith($seq->i_start+1);
    }
    if (defined $lo) {
      foreach my $value ($lo .. $hi) {
        #### $value
        if ($seq->pred($value)) {
          push @got, $value;
        }
      }
    }
    my $got = \@got;
    ### $got

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
      if (defined $values_min
          && defined $data_min
          && $values_min != $data_min) {
        $good = 0;
        MyTestHelpers::diag ("bad: $name values_min $values_min but data min $data_min");
      }
    }
    {
      my $values_max = $seq->values_max;
      if (defined $values_max) {
        my $data_max = _max(@$want);
        if ($values_max != $data_max) {
          $good = 0;
          MyTestHelpers::diag ("bad: $name values_max=$values_max not seen in data, only $data_max");
        }
      }
    }
  }

  $total_checks++;
  # MyTestHelpers::diag ("done");
}

#------------------------------------------------------------------------------
# forced

# check_class ('A086746',
#              'Math::NumSeq::Multiples',
#              [ multiples => 3018, i_start => 1 ]);
# exit 0;


#------------------------------------------------------------------------------
# duplicates or uncatalogued


# check_class ('A010701',
#              'Math::NumSeq::FractionDigits',
#              [ fraction => '10/3', radix => 10 ]);

# check_class ('A010701', 'Math::NumSeq::FractionDigits',
#              [ fraction => '10/3' ]);


#------------------------------------------------------------------------------
# OEIS-Other vs files

{
  system("perl ../ns/tools/make-oeis-catalogue.pl --module=TempOther --other=only") == 0
    or die;
  require 'lib/Math/NumSeq/OEIS/Catalogue/Plugin/TempOther.pm';
  unlink  'lib/Math/NumSeq/OEIS/Catalogue/Plugin/TempOther.pm' or die;

  MyTestHelpers::diag ("\"Other\" uncatalogued sequences:");
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

{
  MyTestHelpers::diag ("Catalogued sequences:");
  my $catalogue = 'Math::NumSeq::OEIS::Catalogue::Plugin::Alpha';
  for (my $anum = $catalogue->anum_first;  #  'A007770';
       defined $anum;
       $anum = $catalogue->anum_after($anum)) {
    ### $anum

    my $info = $catalogue->anum_to_info($anum);
    if (! $info) {
      $good = 0;
      MyTestHelpers::diag ("bad: $anum");
      MyTestHelpers::diag ("anum_to_info() false: ",$info);
      next;
    }
    if ($info->{'class'} eq 'Math::NumSeq::OEIS::File') {
      next;
    }
    ### $info

    check_class ($info->{'anum'},
                 $info->{'class'},
                 $info->{'parameters'});
  }
}

MyTestHelpers::diag ("total checks $total_checks");
ok ($good);

exit 0;
