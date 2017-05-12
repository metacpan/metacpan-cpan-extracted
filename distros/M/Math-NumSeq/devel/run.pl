#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use POSIX;
use Math::PlanePath::Base::Generic 'is_infinite';

# use Smart::Comments;

use lib 'devel/lib';

use constant DBL_INT_MAX => (FLT_RADIX**DBL_MANT_DIG - 1);


$|=1;

{
  my $pred_upto = 0;
  
  my $values_class;
  # $values_class = $gen->values_class('Emirps');
  # $values_class = $gen->values_class('UndulatingNumbers');
  # $values_class = $gen->values_class('TernaryWithout2');
  # $values_class = $gen->values_class('PrimeQuadraticEuler');
  # $values_class = $gen->values_class('Base4Without3');
  # $values_class = $gen->values_class('Tribonacci');
  # $values_class = $gen->values_class('Perrin');
  # $values_class = $gen->values_class('Expression');
  # $values_class = $gen->values_class('Pentagonal');
  # $values_class = $gen->values_class('TwinPrimes');
  # # $values_class = $gen->values_class('DigitsModulo');
  # $values_class = $gen->values_class('RadixWithoutDigit');
  # $values_class = $gen->values_class('Odd');
  # # $values_class = $gen->values_class('MathSequence');
  # $values_class = $gen->values_class('DigitLength');
  # $values_class = $gen->values_class('SumXsq3Ysq');
  # $values_class = $gen->values_class('ReverseAddSteps');
  # $values_class = $gen->values_class('Harshad');
  # $values_class = $gen->values_class('TotientPerfect');
  require Math::NumSeq::DigitLength;
  $values_class = 'Math::NumSeq::DigitLength';
  $values_class = 'Math::NumSeq::DigitProduct';
  $values_class = 'Math::NumSeq::KlarnerRado';
  $values_class = 'Math::NumSeq::Kolakoski';
  $values_class = 'Math::NumSeq::UlamSequence';
  $values_class = 'Math::NumSeq::ReplicateDigits';
  $values_class = 'Math::NumSeq::SumTwoSquares';
  $values_class = 'Math::NumSeq::CunninghamChain';
  $values_class = 'Math::NumSeq::CunninghamPrimes';
  $values_class = 'Math::NumSeq::DigitMiddle';
  $values_class = 'Math::NumSeq::SqrtEngel';
  $values_class = 'Math::NumSeq::RepdigitRadix';
  $values_class = 'Math::NumSeq::KolakoskiMajority';
  $values_class = 'Math::NumSeq::StarNumbers';
  $values_class = 'Math::NumSeq::ReverseAddSteps';
  $values_class = 'Math::NumSeq::Expression';
  $values_class = 'Math::NumSeq::PiDigits';
  $values_class = 'Math::NumSeq::AsciiSelf';
  $values_class = 'Math::NumSeq::Squareful';
  $values_class = 'Math::NumSeq::SquareFreeKernel';
  $values_class = 'Math::NumSeq::SqrtContinued';
  $values_class = 'Math::NumSeq::SqrtContinuedPeriod';
  $values_class = 'Math::NumSeq::PolignacObstinate';
  $values_class = 'Math::NumSeq::RepdigitRadix';
  $values_class = 'Math::NumSeq::SieveMultiples';
  $values_class = 'Math::NumSeq::ReverseAdd';
  $values_class = 'Math::NumSeq::PythagoreanHypots';
  $values_class = 'Math::NumSeq::AbsCubicDiff';
  $values_class = 'Math::NumSeq::RepdigitAny';
  $values_class = 'Math::NumSeq::Loeschian';
  $values_class = 'Math::NumSeq::UndulatingNumbers';
  $values_class = 'Math::NumSeq::HofstadterFigure';
  $values_class = 'Math::NumSeq::TwinPrimes';
  $values_class = 'Math::NumSeq::PierpontPrimes';
  $values_class = 'Math::NumSeq::DedekindPsiSteps';
  $values_class = 'Math::NumSeq::TotientPerfect';
  $values_class = 'Math::NumSeq::TotientSteps';
  $values_class = 'Math::NumSeq::DeletablePrimes';
  $values_class = 'Math::NumSeq::LipschitzClass';
  $values_class = 'Math::NumSeq::GolombSequence';
  $values_class = 'Math::NumSeq::GolayRudinShapiroCumulative';
  $values_class = 'Math::NumSeq::BinaryUndulants';
  $values_class = 'Math::NumSeq::FractionDigits';
  $values_class = 'Math::NumSeq::Tribonacci';
  $values_class = 'Math::NumSeq::SelfLengthCumulative';
  $values_class = 'Math::NumSeq::Tetrahedral';
  $values_class = 'Math::NumSeq::ConcatNumbers';
  $values_class = 'Math::NumSeq::DigitLengthCumulative';
  $values_class = 'Math::NumSeq::Primorials';
  $values_class = 'Math::NumSeq::Factorials';
  $values_class = 'Math::NumSeq::MoranNumbers';
  $values_class = 'Math::NumSeq::CullenNumbers';
  $values_class = 'Math::NumSeq::WoodallNumbers';
  $values_class = 'Math::NumSeq::HypotCount';
  $values_class = 'Math::NumSeq::ErdosSelfridgeClass';
  $values_class = 'Math::NumSeq::GoldbachCount';
  $values_class = 'Math::NumSeq::LemoineCount';
  $values_class = 'Math::NumSeq::EratosthenesStage';
  $values_class = 'Math::NumSeq::ReReplace';
  $values_class = 'Math::NumSeq::SqrtContinued';
  $values_class = 'Math::NumSeq::PrimeIndexOrder';
  $values_class = 'Math::NumSeq::KaprekarSteps';
  $values_class = 'Math::NumSeq::Padovan';
  $values_class = 'Math::NumSeq::StoehrSequence';
  $values_class = 'Math::NumSeq::PrimeFactorExtract';
  $values_class = 'Math::NumSeq::PowerSieve';
  $values_class = 'Math::NumSeq::DigitProductSteps';
  $values_class = 'Math::NumSeq::KaprekarNumbers';
  $values_class = 'Math::NumSeq::LongFractionPrimes';
  $values_class = 'Math::NumSeq::Squares';
  $values_class = 'Math::NumSeq::SpiroFibonacci';
  $values_class = 'Math::NumSeq::Aronson';
  $values_class = 'Math::NumSeq::Repdigits';
  $values_class = 'Math::NumSeq::AllPrimeFactors';
  $values_class = 'Math::NumSeq::MaxDigitCount';
  $values_class = 'Math::NumSeq::PrimeExponentFlip';
  $values_class = 'Math::NumSeq::PrimesDigits';
  $values_class = 'Math::NumSeq::Plaindromes';
  $values_class = 'Math::NumSeq::DuffinianNumbers';
  $values_class = 'Math::NumSeq::ReRound';
  $values_class = 'Math::NumSeq::SophieGermainPrimes';
  $values_class = 'Math::NumSeq::PrimeSignatureLeast';
  $values_class = 'Math::NumSeq::FibonacciProducts';
  $values_class = 'Math::NumSeq::Runs';
  $values_class = 'Math::NumSeq::Pow2Mod10';
  $values_class = 'Math::NumSeq::JacobsthalFunction';
  $values_class = 'Math::NumSeq::GolayRudinShapiro';
  $values_class = 'Math::NumSeq::PrimeFactorCount';
  $values_class = 'Math::NumSeq::MobiusFunction';
  $values_class = 'Math::NumSeq::LiouvilleFunction';
  $values_class = 'Math::NumSeq::BalancedBinary';
  $values_class = 'Math::NumSeq::CbrtContinued';
  $values_class = 'Math::NumSeq::AlphabeticalLength';
  $values_class = 'Math::NumSeq::AlphabeticalLengthSteps';
  $values_class = 'Math::NumSeq::SevenSegments';
  $values_class = 'Math::NumSeq::AlgebraicContinued';
  $values_class = 'Math::NumSeq::PisanoPeriod';
  $values_class = 'Math::NumSeq::JugglerSteps';
  $values_class = 'Math::NumSeq::FibonacciWord';
  $values_class = 'Math::NumSeq::LucasSequenceModulo';
  $values_class = 'Math::NumSeq::Polygonal';
  $values_class = 'Math::NumSeq::RadixConversion';
  $values_class = 'Math::NumSeq::SqrtDigits';
  $values_class = 'Math::NumSeq::PisanoPeriodSteps';
  $values_class = 'Math::NumSeq::DigitCountHigh';
  $values_class = 'Math::NumSeq::DigitCountLow';
  $values_class = 'Math::NumSeq::OEIS';
  $values_class = 'Math::NumSeq::FactorialProducts';
  $values_class = 'Math::NumSeq::Products';
  $values_class = 'Math::NumSeq::DigitSumModulo';
  $values_class = 'Math::NumSeq::Catalan';
  $values_class = 'Math::NumSeq::Fibbinary';
  $values_class = 'Math::NumSeq::DigitCount';
  $values_class = 'Math::NumSeq::FibbinaryBitCount';
  $values_class = 'Math::NumSeq::HappyNumbers';
  $values_class = 'Math::NumSeq::RadixWithoutDigit';
  $values_class = 'Math::NumSeq::LeastPrimitiveRoot';
  $values_class = 'Math::NumSeq::DedekindPsiCumulative';
  $values_class = 'Math::NumSeq::SumPowSub1';
  $values_class = 'Math::NumSeq::LuckyNumbers';
  $values_class = 'Math::NumSeq::ProthNumbers';
  $values_class = 'Math::NumSeq::HafermanCarpet';
  $values_class = 'Math::NumSeq::PlanePathTurn';
  $values_class = 'Math::NumSeq::DivisorCount';
  $values_class = 'Math::NumSeq::PowerPart';
  $values_class = 'Math::NumSeq::Abundant';
  $values_class = 'Math::NumSeq::DigitExtract';
  $values_class = 'Math::NumSeq::SternDiatomic';
  $values_class = 'Math::NumSeq::OEIS::File';
  $values_class = 'Math::NumSeq::CollatzSteps';
  $values_class = 'Math::NumSeq::PrimeIndexPrimes';
  $values_class = 'Math::NumSeq::FibonacciRepresentations';
  $values_class = 'Math::NumSeq::Fibonacci';
  $values_class = 'Math::NumSeq::SlopingExcluded';
  $values_class = 'Math::NumSeq::LucasNumbers';
  $values_class = 'Math::NumSeq::PlanePathDelta';
  $values_class = 'Math::NumSeq::AlmostPrimes';
  $values_class = 'Math::NumSeq::PlanePathCoord';
  $values_class = 'Math::NumSeq::PlanePathN';
  $values_class = 'Math::NumSeq::Pell';
  $values_class = 'Math::NumSeq::Powerful';
  $values_class = 'Math::NumSeq::FibonacciRepresentations';
  $values_class = 'Math::NumSeq::Palindromes';
  $values_class = 'Math::NumSeq::Xenodromes';
  
  eval "require $values_class; 1" or die $@;
  my $seq = $values_class->new
    (
     powerful_type => 'some',
     power => 1,
     
     level => 11,
     # on_values => 'even',
     # end_type => 'to_peak',
     step_type => 'down',
     
     # extract_type => 'middle_lower',
     # extract_offset => 0,
     
     # abundant_type => 'primitive',
     # abundant_type => 'non-primitive',
     
     # _dont_use_bfile => 1,
     # anum  => 'A000110', # 9.7mb A-file
     # anum  => 'A151725',
     # anum  => 'A151725',
     # anum  => 'A196199', # bfile
     # anum  => 'A194831', # small bfile
     anum  => 'A102419',
     
     # root_type => 'negative',
     # digit => 0,
     # radix => 3,
     # i_start => 1,
     # modulus => 2,
     
     # of => 'Primorials',
     # of => 'Fibonacci',
     # of => 'Catalan',
     # multiplicity => 'distinct',
     # fibonacci_word_type=>'dense',
     # initial_0 => 1,
     # initial_1 => 0,
     # modulus => 2,
     # expression => '5throot 2',
     # expression => 'cbrt 7',
     # i_start => 1,
     # cbrt => 2,
     # conjunctions => 1,
     # values_type => 'log',
     # values_type => 'odd',
     # lang => 'fr',
     
     # runs_type => '1to2N',
     # values_type => 'mod2',
     
     # extra_multiples => 0,
     # radix => 10,
     # order => 'sorted',
     # order => 'descending',
     # digit => 1,
     # root_type => 'negative',
     # letter => '',
     # order => 'descending',
     # on_values => 'even',
     # i_start => 0,
     # recurrence_type => 'absdiff',
     # i_start => 0,
     # on_values => 'primes',
     # level_type => 'exact',
     # stage => 1,
     
     # p_or_m => '-',
     # using_values => 'primes',
     # values_type => 'radix',
     # concat_count => 3,
     # radix => 2,
     # sqrt => 120,
     
     # order => 'forward',
     # fraction => '1/14',
     # from_radix => 10,
     #  to_radix => 16,
     # extra_multiples => 1,
     # using_values => 'primes',
     # fibonacci_word_type => 'dense',
     # including_self => 0,
     # offset => 3,
     
     # planepath => 'Diagonals,x_start=1,y_start=1,direction=up',
     # planepath => 'OneOfEight,parts=3side',
     # planepath => 'RationalsTree,tree_type=AYT',
     # planepath => 'Corner',
     # planepath => 'SierpinskiTriangle,align=diagonal',
     # planepath => 'DivisibleColumns,divisor_type=proper,n_start=2',
     # planepath => 'CellularRule,rule=2,n_start=0',
     # planepath => 'DiagonalRationals,direction=up',
     # planepath => 'SierpinskiTriangle,align=diagonal',
     # planepath => 'RationalsTree,tree_type=L',
     # planepath => 'PyramidRows,step=3',
     # planepath => 'LCornerTree,parts=diagonal-1',
     # planepath => 'UlamWarburton,parts=4',
     # planepath => 'DragonCurve',
     # planepath => 'Godfrey',
     planepath => 'AlternatePaper',
     #planepath => 'CCurve',
     # coordinate_type => 'Revisit',
     # coordinate_type => 'NumOverlap',
     # coordinate_type => 'TRSquared',
     # coordinate_type => 'NumSiblings',
     # coordinate_type => 'AbsDiff',
     
     # planepath => 'PythagoreanTree,coordinates=AC',
     # planepath => 'RationalsTree,tree_type=L',
     # planepath => 'R5DragonMidpoint,arms=1',
     # planepath => 'CellularRule,rule=84',
     # planepath => 'PyramidRows,step=2',
     # planepath => 'Columns,height=2,n_start=0',
     # planepath => 'MultipleRings,step=0,ring_shape=circle',
     # delta_type=>'dTRadius',
     
     # planepath => 'MultipleRings,step=1,ring_shape=circle',
     # planepath => 'Diagonals',
     # planepath => 'PythagoreanTree,coordinates=BC',
     # planepath => 'ChanTree,k=4',
     # planepath => 'SquareSpiral',
     # planepath => 'PowerArray,radix=4',
     # turn_type => 'SLR',
     
     # planepath => 'CfracDigits',
     # planepath => 'RationalsTree',
     # planepath => 'UlamWarburton,n_start=1',
     # planepath => 'UlamWarburtonQuarter,n_start=0',
     # planepath => 'ChanTree,k=2',
     # planepath => 'SierpinskiCurve,arms=2',
     # planepath => 'ToothpickUpist',
     #planepath => 'ToothpickTreeByCells,parts=octant',
     # planepath => 'LCornerTreeByCells,parts=wedge+1',
     #  planepath => 'DigitGroups,radix=2',
     # planepath => 'CellularRule,rule=206',
     # planepath => 'QuadricIslands',
     # line_type => 'Depth_start',
     # planepath => 'WythoffArray,x_start=1,y_start=1',
     line_type => 'X_axis',
     # line_type => 'Depth_end',
     # i_start => 1,
     
     # start => 5,
     # including_repdigits => 1,
     
     # i_start => 3,
     
     # including_one => 1,
     # start => 1,
     # pythagorean_type => 'primitive',
     # prime_type => 'twin',
     # round_count => 2,
     # pairs => 'both',
     # multiples => 1,
     # digit => 1,
     
     # order => 'forward',
     # including_self => 0,
     #
     # expression_evaluator => 'MS',
     # expression => '2*i+1',
     # # # expression => 'z=3; z*x^2 + 3*x + 2',
     # # # expression => 'x^2 + 3*x + 2',
     # # # expression => 'atan(x)',
     # # expression => '9*i*i',
     #
     # factor_count => 8,
     #
     # round => 'lower',
     #
     # length => 2,
     # which => 'last',
     
     # polygonal => 18,
     # pairs => 'second',
     
     # including_zero => 1,
     # # divisors_type => 'proper',
     # # algorithm_type => '1/2-3/2',
     # # algorithm_type => '1/3-3/2',
     # lo => 0,
     # hi => 10, # 200*$rep,
     # where => 'low',
    );
  my $hi = 103;
  
  my $i_start = $seq->i_start;
  print "i_start $i_start\n";
  print "anum ",($seq->oeis_anum//'[undef]'),"\n";
  print "description: ",($seq->description//'[undef]'),"\n";
  print "values_min ",($seq->values_min//'[undef]'),"\n";
  print "values_max ",($seq->values_max//'[undef]'),"\n";
  print "characteristic(increasing) ",($seq->characteristic('increasing')//'[undef]'),"\n";
  print "characteristic(non_decreasing) ",($seq->characteristic('non_decreasing')//'[undef]'),"\n";
  print "characteristic(smaller)    ",($seq->characteristic('smaller')//'[undef]'),"\n";
  print "characteristic(integer)    ",($seq->characteristic('integer')//'[undef]'),"\n";
  print "characteristic hash: ",join(', ',%{$seq->{'characteristic'}||{}}),"\n";
  print "parameters: ",join(', ',map{$_->{'name'}}$seq->parameter_info_list),"\n";
  if (my $planepath_object = $seq->{'planepath_object'}) {
    print "planepath_object ",ref $planepath_object,"\n";
  }
  print "\n";
  
  my $values_min = $seq->values_min;
  my $values_max = $seq->values_max;
  my $saw_values_min;
  my $saw_values_max;
  my $prev_value;
  my $prev_i;
  
  foreach my $rep (1 .. 2) {
    ### $seq
    if (my $radix = $seq->characteristic('digits')) {
      print "  radix $radix\n";
    }
    print "by next(): ";
    my $show_i = 1;
    
    my $check_pred_upto = ! $seq->characteristic('digits')
      && ! $seq->characteristic('count');
    
    foreach my $want_i ($i_start .. $i_start + $hi) {
      my @ret = $seq->next;
      my ($i,$value) = @ret;
      if (@ret == 0) {
        print "[end]\n";
        last;
      }
      if ($show_i) {
        print "i=$i ";
        $show_i = 0;
      }
      if (defined $value) {
        print "$value,";
        if (defined $values_min && $value < $values_min - 0.00000001) {
          print " oops i=$i, value < values_min=$values_min\n";
        }
        if (defined $values_max && $value > $values_max + 0.00000001) {
          print " oops i=$i, value > values_max=$values_max\n";
        }
        if (! defined $saw_values_min || $value < $saw_values_min) {
          $saw_values_min = $value;
        }
        if (! defined $saw_values_max || $value > $saw_values_max) {
          $saw_values_max = $value;
        }
        # if ($value > DBL_INT_MAX) {
        #   print "\nstop at DBL_INT_MAX\n";
        #   last;
        # }
      } else {
        print "undef,";
      }
      if ($i != $want_i) {
        print " oops, i=$i expected i=$want_i\n";
      }


      if ($seq->can('pred')) {
        if (! $seq->pred($value)) {
          print " oops, pred($value) false\n";
        }
        unless ($seq->characteristic('count')
                || ! $seq->characteristic('non_decreasing')
                || $seq->characteristic('smaller')
                || $value - $pred_upto > 1000) {
          while ($pred_upto < $value) {
            if ($seq->pred($pred_upto)) {
              print " oops, pred($pred_upto) is true\n";
            }
            $pred_upto++;
          }
          $pred_upto = $value+1;
        }
      }
      if ($seq->can('value_to_i_floor')) {
        {
          my $i_floor = $seq->value_to_i_floor($value);
          unless ($i_floor == $i) {
            print " oops, value_to_i_floor($value)=$i_floor want i=$i\n";
          }
        }
        {
          my $try_value = $value - 1;
          unless (defined $prev_value && $try_value == $prev_value) {
            my $want_i = ($try_value < $values_min ? $i_start : $i - 1);
            if (defined $want_i && $want_i < $i_start) { $want_i = undef; }
            my $i_floor = $seq->value_to_i_floor($try_value);
            unless (equal($i_floor, $want_i)) {
              $want_i //= 'undef';
              print " oops, value_to_i_floor($value-1=$try_value)=$i_floor want_i=$want_i\n";
            }
          }
        }
      }
      if ($seq->can('value_to_i')) {
        {
          my $i_reverse = $seq->value_to_i($value);
          unless ($i_reverse == $i) {
            print " oops, value_to_i($value)=$i_reverse want i=$i\n";
          }
        }
        {
          my $try_value = $value - 1;
          unless (defined $prev_value && $try_value == $prev_value) {
            my $i_reverse = $seq->value_to_i($try_value);
            if (defined $i_reverse) {
              print " oops, value_to_i($value-1=$try_value)=$i_reverse expected undef\n";
            }
          }
        }
      }
      if ($seq->can('ith')) {
        if (! is_infinite($value) && $value >= 2**50) {
          require Math::BigInt;
          $i = Math::BigInt->new($i);
        }
        my $ith_value = $seq->ith($i);
        unless ((defined $value == defined $ith_value)
                && (! defined $value
                    || $ith_value == $value
                    || abs ($ith_value - $value) < 0.0000001)) {
          print " oops, ith($i)=",$ith_value//'undef'," next=",$value//'undef',"\n";
        }
      }
      $prev_value = $value;
      $prev_i = $i;
    }
    print "\n";
    if (defined $values_min && $saw_values_min != $values_min) {
      print "hmm, saw_values_min=$saw_values_min not seq->values_min=$values_min\n";
    }
    if (defined $values_max && $saw_values_max != $values_max) {
      print "hmm, saw_values_max=$saw_values_max not seq->values_max=$values_max\n";
    }
    if ($rep < 2) {
      print "rewind\n";
      $seq->rewind;
      undef $prev_value;
    }
  }

  if ($seq->can('ith')) {
    print "by ith():      ";
    foreach my $i ($seq->i_start .. $seq->i_start + $hi - 1) {
      my $value = $seq->ith($i);
      if (! defined $value) {
        print "undef\n";
        if ($i > 3) {
          last;
        } else {
          next;
        }
      }
      if (defined $value) {
        print "$value,";
        #print "$i=$value,";
      } else {
        print "$i,";
        $value=$i;
      }
      if ($value > DBL_INT_MAX) {
        last;
      }

      if ($seq->can('pred') && ! $seq->pred($value)) {
        print " oops, pred($value) false\n";
      }
    }
    print "\n";
  }

  if ($seq->can('ith_pair') && $seq->can('ith_pair') != \&Math::NumSeq::ith_pair) {
    print "by ith_pair():      ";
    foreach my $i ($seq->i_start .. $seq->i_start + $hi - 1) {
      my ($value,$v1) = $seq->ith_pair($i);
      if (! defined $value) {
        print "undef\n";
        if ($i > 3) {
          last;
        } else {
          next;
        }
      }
      if (defined $value) {
        print "$value,";
        #print "$i=$value,";
      } else {
        print "$i,";
        $value=$i;
      }
      if ($value > DBL_INT_MAX) {
        last;
      }

      my $vv0 = $seq->ith($i);
      my $vv1 = $seq->ith($i+1);
      if ($value != $vv0 || $v1 != $vv1) {
        print " oops, ith_pair($i)=$value,$v1 but ith($i,$i+1)=$vv0,$vv1\n";
      }
    }
    print "\n";
  }

  if ($seq->can('pred')
      && ! ($seq->characteristic('count'))) {
    print "by pred(): ";
    foreach my $value (0 .. $hi - 1) {
      if ($seq->pred($value)) {
        print "$value,";
        #print "$i=$value,";
      }
      if ($value > DBL_INT_MAX) {
        last;
      }
    }
    print "\n";
  }

  if ($seq->can('value_to_i_estimate')) {
    my $est_i = $seq->value_to_i_estimate($prev_value);
    my $f = $est_i/($prev_i||1);
    $f = sprintf '%.4f', $f;
    printf "value_to_i_estimate($prev_value) i=$prev_i est=$est_i  f=$f\n";
  }

  foreach my $method ('ith','pred') {
    if ($seq->can($method) && eval { require Data::Float }) {
      print "$method(0): ";
      print $seq->$method(0)//'undef',"\n";
      print "$method(-1): ";
      print $seq->$method(-1)//'undef',"\n";
      print "$method(pos_infinity): ";
      print $seq->$method(Data::Float::pos_infinity())//'undef',"\n";
      print "$method(neg_infinity): ";
      print $seq->$method(Data::Float::neg_infinity())//'undef',"\n";
      {
        print "$method(nan): ";
        my $pred = $seq->$method(Data::Float::nan());
        print $pred//'undef',"\n";
        if ($method eq 'pred' && $pred) {
          print "     **** oops\n";
        }
        # if ($method eq 'ith' && defined $pred) {
        #   print "     **** maybe oops\n";
        # }
      }

      # Note: not "require Math::BigFloat" since it does tie-ins to BigInt
      # in its import
      eval "use Math::BigFloat; 1" or die;
      print "$method(biginf): ";
      print $seq->$method(Math::BigFloat->binf())//'undef',"\n";
      print "$method(neg biginf): ";
      print $seq->$method(Math::BigFloat->binf('-'))//'undef',"\n";
      {
        print "$method(bignan): ";
        my $pred = $seq->$method(Math::BigFloat->bnan);
        print $pred//'undef',"\n";
        if ($method eq 'pred' && $pred) {
          print "     **** oops\n";
        }
        if ($method eq 'ith' && defined $pred && $pred==$pred) {
          print "     **** oops, ith(nan) should be nan\n";
        }
      }
    }
  }
  print "done\n";
  exit 0;
}

sub equal {
  my ($x,$y) = @_;
  return ((defined $x && defined $y && $x == $y)
          || (! defined $x && ! defined $y));
}

{
  my $i;
  sub del {
    my ($n) = @_;
    # return 2 + ($] >= 5.006 ? 3 : 999);
    return $n * (1/sqrt(2));
  }
  my %read_signal = ('has-screen' => 'screen-changed',
                     style        => 'style-set',
                     toplevel     => 'hierarchy-changed');
  sub read_signals {
    my ($self) = @_;
    my $pname = $self->{'pname'};
    return ($read_signal{$pname} || "$pname-changed");
  }

  require Math::PlanePath::MultipleRings;
  require Math::NumSeq::PrimeQuadraticHonaker;
  require B::Concise;
  # B::Concise::compile('-exec',\&Math::NumSeq::PrimeQuadraticHonaker::pred)->();
  B::Concise::compile('-exec',\&Math::PlanePath::MultipleRings::_xy_to_d)->();
  exit 0;
}


{
  require Math::BigInt;
  Math::BigInt->import (try => 'GMP');

  require Devel::TimeThis;
  my $t = Devel::TimeThis->new('x');

  my $k = 2;
  my $bits = 500000;
  my $num = Math::BigInt->new($k);
  $num->blsft ($bits);
  ### num: "$num"
  $num->blog();
  # $num->bsqrt();
  ### num: "$num"
  my $str = $num->as_bin;
  ### $str

  # $num = Math::BigInt->new(1);
  # $num->blsft (length($str)-1);
  # ### num: "$num"

  exit 0;
}





{
  my @catalan = (1);
  foreach my $i (1 .. 20) {
    my $c = 0;
    foreach my $j (0 .. $#catalan) {
      $c += $catalan[$j]*$catalan[-1-$j];
    }
    $catalan[$i] = $c;
    print "$c\n";
  }
  exit 0;
}




{
  # # use Memoize;
  # # memoize('bell_number');
  # my @bell;
  # sub bell_number {
  #   my $n = shift;
  #   if ($n < @bell) {
  #     return $bell[$n];
  #   }
  #   return undef if $n < 0;
  #   return 1     if $n == 0;
  #   my $bell = 0;
  #   for (0 .. $n - 1) {
  #     my $bin = Math::Symbolic::AuxFunctions::binomial_coeff( $n - 1, $_ );
  #     $bell += bell_number($_) * $bin;
  #     ### $bin
  #     ### $bell
  #   }
  #   ### return: $bell
  #   $bell[$n] = $bell;
  #   return $bell;
  # }

  require Math::Symbolic::AuxFunctions;
  foreach my $i (1 .. 50) {
    my $b = Math::Symbolic::AuxFunctions::bell_number($i);
    # my $b = bell_number($i);
    printf "%2d  %f\n", $i, $b;
  }
  exit 0;
}
{
  require Module::Util;
  my @modules = Module::Util::find_in_namespace
    ('App::MathImage::NumSeq');
  ### @modules
  exit 0;
}


{
  sub base3 {
    my ($n) = @_;
    my $str = '';
    while ($n) {
      $str = ($n % 3) . $str;
      $n = int($n/3);
    }
    return $str;
  }
  foreach my $n (1 .. 20) {
    printf "%2d %4s\n", $n, base3($n);
  }

  require App::MathImage::Generator;
  my $gen = App::MathImage::Generator->new (fraction => '5/29',
                                            polygonal => 3);
  my $iter = $gen->values_make_ternary_without_2;
  foreach my $i (1 .. 20) {
    my $count = 0;
    my $n = $iter->();
    printf "%2d %4s\n", $n, base3($n);
  }
  exit 0;
}

{
  require Math::Trig;
  my $x;
  foreach (my $i = 1; $i < 10000000; $i++) {
    my $multiple = $i * 7;
    my $r = 0.5/sin(Math::Trig::pi()/$multiple);
    $x //= $r-1;
    if ($r - $x < 1) {
      printf "%2d %3d %8.3f  %6.3f\n", $i, $multiple, $r, $i*$x;
      die $i;
    }
    $x = $r;
  }
  exit 0;
}

{
  require POSIX;
  require Math::Trig;
  my $r = 1;
  my $theta = 0;
  my $ang = 0;
  foreach my $n (1 .. 100) {
    printf "%2d  ang=%.3f  %.3f %.3f %.3f\n",
      $n, $ang, $r, $ang, POSIX::fmod($ang, 2*3.14159);
    $ang = Math::Trig::asin(1/$r) / (2*3.14159);
    $theta += $ang;
    $r += $ang;
  }
  exit 0;
}

{
  require String::Parity;
  require String::BitCount;
  my $i = 0xFFFF01;
  my $s = pack('N', $i);
  $s = "\x{7FF}";
  my $b = [unpack('%32b*', $s)];
  my $p = 0; #String::Parity::isOddParity($s);
  my $c = 0; # String::BitCount::BitCount($s);
  ### $i
  ### $s
  ### $b
  ### $p
  ### $c
  exit 0;
}

{
  require Path::Class;
  require Scalar::Util;
  my $dir = Path::Class::dir('/', 'tmp');
  ### $dir
  my $reftype = Scalar::Util::reftype($dir);
  ### $reftype
  exit 0;
}
{
  require Scalar::Util;
  @ARGV = ('--values=xyz');
  Getopt::Long::GetOptions
      ('values=s'  => sub {
         my ($name, $value) = @_;
         ### $name
         ### ref: ref($name)
         my $reftype = Scalar::Util::reftype($name);
         ### $reftype
         ### $value
         ### ref: ref($value)
       });
  exit 0;
}

{
  require Getopt::Long;
  require Scalar::Util;
  @ARGV = ('--values=xyz');
  Getopt::Long::GetOptions
      ('values=s'  => sub {
         my ($name, $value) = @_;
         ### $name
         ### ref: ref($name)
         my $reftype = Scalar::Util::reftype($name);
         ### $reftype
         ### $value
         ### ref: ref($value)
       });
  exit 0;
}

{
  my $subr = sub {
    my ($s) = @_;
    return $s*(16*$s - 56) + 50;
     return 3*$s*$s - 4*$s + 2;
    return 2*$s*$s - 2*$s + 2;
    return $s*$s + .5;
    return $s*$s - $s + 1;
    return $s*($s+1)*.5 + 0.5;
  };
  my $back = sub {
    my ($n) = @_;
    return (7 + sqrt($n - 1)) / 4;
    return (2 + sqrt(3*$n - 2)) / 3;
    return .5 + sqrt(.5*$n-.75);
    return sqrt ($n - .5);
    # return -.5 + sqrt(2*$n - .75);
    #    return int((sqrt(4*$n-1) - 1) / 2);
  };
  my $prev = 0;
  foreach (1..15) {
    my $this = $subr->($_);
    printf("%2d  %.2f  %.2f  %.2f\n", $_, $this, $this-$prev,$back->($this));
    $prev = $this;
  }
  for (my $n = 1; $n < 100; $n++) {
    printf "%.2f  %.2f\n", $n,$back->($n);
  }
  exit 0;
}



{
  require Math::Libm;
  my $pi = Math::Libm::M_PI();
  $pi *= 2**30;
  print $pi,"\n";
  printf ("%b", $pi);
  exit 0;
}


{
  require Math::PlanePath::SquareSpiral;
  require Math::PlanePath::Diagonals;
  my $path = Math::PlanePath::SquareSpiral->new;
  # my $path = Math::PlanePath::Diagonals->new;
  # print $path->rect_to_n_range (0,0, 5,0);
  foreach (1 .. 1_000_000) {
    $path->n_to_xy ($_);
  }
  exit 0;
}

{
  require Math::Fibonacci;
  require POSIX;
  my $phi = (1 + sqrt(5)) / 2;
  foreach my $i (1 .. 1000) {
    my $theta = $i / ($phi*$phi);
    my $frac = $theta - POSIX::floor($theta);
    if ($frac < 0.02 || $frac > 0.98) {
      printf("%2d  %1.3f  %5.3f\n",
             $i, $frac, $theta);
    }
  }
  exit 0;
}

{
  require Math::Fibonacci;
  require POSIX;
  my $phi = (1 + sqrt(5)) / 2;
  foreach my $i (1 .. 40) {
    my $f = Math::Fibonacci::term($i);
    my $theta = $f / ($phi*$phi);
    my $frac = $theta - POSIX::floor($theta);
    printf("%2d  %10.2f  %5.2f  %1.3f  %5.3f\n",
           $i, $f, sqrt($f), $frac, $theta);
  }
  exit 0;
}
{
  require Math::Fibonacci;
  my @f = Math::Fibonacci::series(90);
  local $, = ' ';
  print @f,"\n";

  foreach my $i (1 .. $#f) {
    if ($f[$i] > $f[$i]) {
      print "$i\n";
    }
  }
  my @add = (1, 1);
  for (;;) {
    my $n = $add[-1] + $add[-2];
    if ($n > 2**53) {
      last;
    }
    push @add, $n;
  }
  print "add count ",scalar(@add),"\n";
  foreach my $i (0 .. $#add) {
    if ($f[$i] != $add[$i]) {
      print "diff $i    $f[$i] != $add[$i]    log ",log($add[$i])/log(2),"\n";
    }
  }
  exit 0;
}

#     my $count = POSIX::ceil (log($n_pixels * sqrt(5)) / log(PHI));
#     @add = Math::Fibonacci::series ($count);
#     if ($option_verbose) {
#       print "fibonacci $count add to $add[-1]\n";
#     }

# miss 1928099
{
  require Math::Prime::XS;
  my @array = Math::Prime::XS::sieve_primes (1, 2000000);
  $,="\n";
#  print @array;
  exit 0;
}

