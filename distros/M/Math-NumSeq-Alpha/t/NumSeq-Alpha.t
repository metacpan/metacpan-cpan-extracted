#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2015 Kevin Ryde

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

# Lingua::POL::Number v? and Lingua::UK::Numbers 0.06 were emitting
# warnings.  Load before nowarnings() so not to fail.  Those modules not
# used in the tests, but Lingua::Any::Numbers (as of its version 0.45) loads
# everything no matter what language is requested.
#
use Lingua::Any::Numbers;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $test_count = (tests => 32)[1];
plan tests => $test_count;

# uncomment this to run the ### lines
#use Smart::Comments '###';

use POSIX ();
POSIX::setlocale(POSIX::LC_ALL(), 'C'); # no message translations

use constant DBL_INT_MAX => (POSIX::FLT_RADIX() ** POSIX::DBL_MANT_DIG());
use constant MY_MAX => (POSIX::FLT_RADIX() ** (POSIX::DBL_MANT_DIG()-5));

sub diff_nums {
  my ($gotaref, $wantaref) = @_;
  for (my $i = 0; $i < @$gotaref; $i++) {
    if ($i > @$wantaref) {
      return "want ends prematurely i=$i";
    }
    my $got = $gotaref->[$i];
    my $want = $wantaref->[$i];
    if (! defined $got && ! defined $want) {
      next;
    }
    if (! defined $got || ! defined $want) {
      return "different i=$i got=".(defined $got ? $got : '[undef]')
        ." want=".(defined $want ? $want : '[undef]');
    }
    if ($got != $want) {
      return "different i=$i numbers got=$got want=$want";
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

#------------------------------------------------------------------------------
my ($pos_infinity, $neg_infinity, $nan);
my ($is_infinity, $is_nan);
if (! eval { require Data::Float; 1 }) {
  MyTestHelpers::diag ("Data::Float not available");
} elsif (! Data::Float::have_infinite()) {
  MyTestHelpers::diag ("Data::Float have_infinite() is false");
} else {
  $is_infinity = sub {
    my ($x) = @_;
    return defined($x) && Data::Float::float_is_infinite($x);
  };
  $is_nan = sub {
    my ($x) = @_;
    return defined($x) && Data::Float::float_is_nan($x);
  };
  $pos_infinity = Data::Float::pos_infinity();
  $neg_infinity = Data::Float::neg_infinity();
  $nan = Data::Float::nan();
}
sub dbl_max {
  require POSIX;
  return POSIX::DBL_MAX();
}
sub dbl_max_neg {
  require POSIX;
  return - POSIX::DBL_MAX();
}

sub ternary {
  my ($str) = @_;
  my $ret = 0;
  foreach my $digit (split //, $str) { # high to low
    $ret = 3*$ret + $digit;
  }
  return $ret;
}

#------------------------------------------------------------------------------
# Math::NumSeq various classes

foreach my $elem
  (
   [ 'Math::NumSeq::AlphabeticalLength',
     [ 3, 3, 5, 4, 4, 3, 5, 5, 4, 3, 6, 6, 8, 8, 7, 7, 9, 8, 8 ], # per POD
   ],
   [ 'Math::NumSeq::AlphabeticalLengthSteps',
     [ 3, 3, 2, 0, 1, 3, 2, 2, 1, 3, 4, 4, 3, 3, 3 ], # per POD
   ],
   [ 'Math::NumSeq::SevenSegments',
     [ 6, 2, 5, 5, 4, 5, 6, 3, 7, 5, 8, 4, 7, 7, 6, 7, 8 ], # per POD
   ],
   [ 'Math::NumSeq::SevenSegments',
     [ 2, 5, 5, 4, 5, 6, 4, 7, 6, 8, 4, 7, 7, 6, 7, 8 ], # per POD
     { i_start => 1, seven => 4, nine => 6 },
   ],
  ) {
  my ($class, $want, $values_options, $test_options) = @$elem;
  $values_options ||= {};
  my $good = 1;
  my $lo = $want->[0];

  ref $want eq 'ARRAY' or die "$class, oops, want array is not an array";

  my $name = join (' ',
                   $class,
                   map {"$_=$values_options->{$_}"} keys %$values_options);

  ### $class
  eval "require $class; 1" or die $@;
  my $seq = $class->new (%$values_options);


  #### $want
  my $hi = $want->[-1];
  # MyTestHelpers::diag ("$name $lo to ",$hi);

  # SKIP: {
  #    require Module::Load;
  #    if (! eval { Module::Load::load ($class);
  #                 $seq = $class->new (lo => $lo,
  #                                     hi => $hi,
  #                                     %$values_options);
  #                 1; }) {
  #      my $err = $@;
  #      diag "$name caught error -- $err";
  #      if (my $module = $test_options->{'module'}) {
  #        if (! eval "require $module; 1") {
  #          skip "$name due to no module $module", 2;
  #        }
  #        diag "But $module loads successfully";
  #      }
  #      die $err;
  #    }

  # next() values, incl after rewind()
  foreach my $rewind (0, 1) {
    {
      my $i = $seq->tell_i;
      ok ($i, $seq->i_start, "$name tell_i() == i_start(), rewind=$rewind");
    }

    my $got = [ map { my ($i, $value) = $seq->next; $value } 0 .. $#$want ];
    foreach (@$got) { if (defined $_ && $_ == 0) { $_ = 0 } }  # avoid "-0"
    foreach (@$got) { if (! defined $_) { $_ = 'undef' } }
    foreach (@$got) { if (ref $_) { $_ = "$_" }
                      elsif ($_ > ~0) { $_ = sprintf "%.0f", $_ } }
    ### ref: ref $got->[-1]

    my $got_str = join(',', @$got);
    my $want_str = join(',', @$want);

    # stray leading "+" from perl 5.6.2 on ConcatNumbers NVs or something
    $got_str =~ s/^\+//;
    $got_str =~ s/,\+/,/g;

    ok ($got_str, $want_str, "$name by next(), lo=$lo hi=$hi");
    if ($got_str ne $want_str) {
      MyTestHelpers::diag ("got len ".scalar(@$got));
      MyTestHelpers::diag ("want len ".scalar(@$want));
      MyTestHelpers::diag ("got  ", substr ($got_str, 0, 256));
      MyTestHelpers::diag ("want ", substr ($want_str, 0, 256));
    }

    ### rewind() ...
    $seq->rewind;
  }

  ### ith() values ...
  {
    my $skip;
    my $got_str;
    if (! $seq->can('ith')) {
      $skip = "$name no ith()";
    } else {
      my $got = [ map { my $i = $_ + $seq->i_start;
                        $seq->ith($i) } 0 .. $#$want ];
      foreach (@$got) { if (defined $_ && $_ == 0) { $_ = 0 } }  # avoid "-0"
      foreach (@$got) { if (! defined $_) { $_ = 'undef' } }
      foreach (@$got) { if (ref $_) { $_ = "$_" }
                        elsif ($_ > ~0) { $_ = sprintf "%.0f", $_ } }
      ### ref: ref $got->[-1]

      $got_str = join(',', @$got);
      # stray leading "+" from perl 5.6.2 on ConcatNumbers NVs or something
      $got_str =~ s/^\+//;
      $got_str =~ s/,\+/,/g;
    }
    my $want_str = join(',', @$want);
    skip ($skip, $got_str, $want_str, "$name by ith(), lo=$lo hi=$hi");
  }

  ### value_to_i() ...
  # value_to_i_floor()
  {
    ### $want
    my $skip;
    my $bad = 0;

    foreach my $p (0 .. $#$want) {
      my $i = $p + $seq->i_start;
      my $value = $want->[$p];

      {
        my $want_i = $i;
        my $want_p = $p;
        # skip back over repeat values
        while ($want_p > 0 && $want->[$want_p-1] == $value) {
          $want_i--;
          $want_p--;
        }
        if ($seq->can('value_to_i')) {
          my $got_i = $seq->value_to_i($value);
          if (! defined $got_i || $got_i != $want_i) {
            MyTestHelpers::diag ("$name value_to_i($value) want $want_i got $got_i");
            $bad++
          }
        }
        if ($seq->can('value_to_i_floor')) {
          my $got_i = $seq->value_to_i_floor($value);
          if (! defined $got_i || $got_i != $want_i) {
            MyTestHelpers::diag ("$name value_to_i_floor($value) want $want_i got $got_i");
            $bad++
          }
        }
      }

      if ($p < $#$want && $value+1 < $want->[$p+1]) {
        {
          my $try_value = $value+0.25;

          if ($seq->can('value_to_i')) {
            my $got_i = $seq->value_to_i($try_value);
            if (defined $got_i) {
              MyTestHelpers::diag ("$name value_to_i($value+0.25=$try_value) want undef got ",$got_i);
              $bad++
            }
          }
          if ($seq->can('value_to_i_floor')) {
            my $got_i = $seq->value_to_i_floor($try_value);
            if ($got_i != $i) {
              MyTestHelpers::diag ("$name value_to_i_floor($value+0.25=$try_value) want $i got $got_i");
              $bad++
            }
          }
        }
        {
          my $try_value = $value+1;

          if ($seq->can('value_to_i')) {
            my $got_i = $seq->value_to_i($try_value);
            if (defined $got_i) {
              MyTestHelpers::diag ("$name value_to_i($value+1=$try_value) want undef got ",$got_i);
              $bad++
            }
          }
          if ($seq->can('value_to_i_floor')) {
            my $got_i = $seq->value_to_i_floor($try_value);
            if ($got_i != $i) {
              MyTestHelpers::diag ("$name value_to_i_floor($value+1=$try_value) want $i got $got_i");
              $bad++
            }
          }
        }
      }

      if ($p == 0 || $value-1 > $want->[$p-1]) {
        {
          my $try_value = $value-0.25;
          my $want_i = $i-1;
          if ($want_i < $seq->i_start) {
            if (defined $test_options->{'value_to_i_floor_below_first'}) {
              $want_i = $test_options->{'value_to_i_floor_below_first'};
            } else {
              $want_i = $seq->i_start;
            }
          }
          if ($seq->can('value_to_i')) {
            my $got_i = $seq->value_to_i($try_value);
            if (defined $got_i) {
              MyTestHelpers::diag ("$name value_to_i($value-0.25=$try_value) want undef got $got_i");
              $bad++
            }
          }
          if ($seq->can('value_to_i_floor')) {
            my $got_i = $seq->value_to_i_floor($try_value);
            if ($got_i != $want_i) {
              MyTestHelpers::diag ("$name value_to_i_floor($value-0.25=$try_value) want $want_i got $got_i");
              $bad++
            }
          }
        }
        {
          my $try_value = $value-1;
          my $want_i = $i-1;
          if ($want_i < $seq->i_start) {
            if (defined $test_options->{'value_to_i_floor_below_first'}) {
              $want_i = $test_options->{'value_to_i_floor_below_first'};
            } else {
              $want_i = $seq->i_start;
            }
          }
          if ($seq->can('value_to_i_floor')) {
            my $got_i = $seq->value_to_i_floor($try_value);
            if ($got_i != $want_i) {
              MyTestHelpers::diag ("$name value_to_i_floor($value-1=$try_value) want $want_i got $got_i");
              $bad++
            }
          }
        }
      }
    }
    my $want_str = join(',', @$want);
    skip ($skip, $bad, 0, "$name value_to_i_floor()");
  }

  # value_to_i_estimate() should be an integer, and should be clean to
  # negatives and zero
  {
    my $skip;
    my $bad = 0;
    if (! $seq->can('value_to_i_estimate')) {
      $skip = "$name no value_to_i_estimate()";
    } else {
      foreach my $value (-100, -1, 0, @$want) {
        my $try_value = $value - 1;
        my $got_i = $seq->value_to_i_estimate($try_value);
        if ($got_i != int($got_i)) {
          MyTestHelpers::diag ("$name value_to_i_estimate($try_value) not an integer: $got_i");
          $bad++
        }
      }
    }
    my $want_str = join(',', @$want);
    skip ($skip, $bad, 0, "$name value_to_i_floor()");
  }

  # infinities and fractions
  foreach my $method ('ith', 'value_to_i_floor', 'value_to_i_estimate') {
    if (! $seq->can($method)) {
      # skip "no $method() for $seq", 1;
    } else {
      if (defined $pos_infinity) {
        # MyTestHelpers::diag ("$method(pos_infinity) ", $name);
        $seq->$method($pos_infinity);
      }
      if (defined $neg_infinity) {
        $seq->$method($neg_infinity);
      }
      if (defined $nan) {
        $seq->$method($nan);
      }
      $seq->$method(0.5);
      $seq->$method(100.5);
      $seq->$method(-1);
      $seq->$method(-100);
      $seq->$method(-0.5);
    }
  }

  # values_min()
  {
    my $values_min = $seq->values_min;
    if (defined $values_min) {
      foreach my $value (@$want) {
        if ($value < $values_min) {
          MyTestHelpers::diag ($name, " value $value less than values_min=$values_min");
          $good = 0;
        }
      }
    }
  }

  ### pred() infinities: $name
  if (! $seq->can('pred')) {
    # MyTestHelpers::diag ("$name -- no pred()");
  } else {

    if (defined $pos_infinity) {
      $seq->pred($pos_infinity);
    }
    if (defined $neg_infinity) {
      $seq->pred($neg_infinity);
    }
    if (defined $nan) {
      if ($seq->pred($nan)) {
        $good = 0;
        MyTestHelpers::diag ($name, " -- pred(nan) should be false");
      }
      if ($seq->pred(-$nan)) {
        $good = 0;
        MyTestHelpers::diag ($name, " -- pred(-nan) should be false");
      }
    }

    {
      my $count = 0;
      foreach my $value (@$want) {
        if (! $seq->pred($value)) {
          $good = 0;
          MyTestHelpers::diag ($name, " -- pred($value) false");
          last if $count++ > 10;
        }
      }
    }

    if ($seq->characteristic('count')) {
      # MyTestHelpers::diag ($name, "-- no pred() on characteristic(count)");
    } elsif ($seq->characteristic('digits')) {
      # MyTestHelpers::diag ($name, "-- no pred() on characteristic(digits)");
    } elsif (! $seq->characteristic('increasing')) {
      # MyTestHelpers::diag ($name, "-- no pred() on not characteristic(increasing)");
    } elsif ($seq->characteristic('modulus')) {
      # MyTestHelpers::diag ($name, "-- no pred() on characteristic(modulus)");
    } else {

      if ($hi > 1000) {
        $hi = 1000;
        $want = [ grep {$_<=$hi} @$want ];
      }
      my @got;
      my $pred_lo = _min(@$want);
      my $pred_hi = $want->[-1];
      for (my $value = $pred_lo; $value <= $pred_hi; $value += 0.5) {
        ### $value
        if ($seq->pred($value)) {
          push @got, $value;
        }
      }
      _delete_duplicates($want);
      #### $want
      my $got = \@got;
      my $diff = diff_nums($got, $want);
      ok ($diff, undef, "$class pred() lo=$lo hi=$hi");
      if (defined $diff) {
        MyTestHelpers::diag ("got len ".scalar(@$got));
        MyTestHelpers::diag ("want len ".scalar(@$want));
        if ($#$got > 200) { $#$got = 200 }
        if ($#$want > 200) { $#$want = 200 }
        MyTestHelpers::diag ("got  ". join(',', map {defined() ? $_ : 'undef'} @$got));
        MyTestHelpers::diag ("want ". join(',', map {defined() ? $_ : 'undef'} @$want));
      }
    }
  }

  ok ($good, 1, $name);
}

#------------------------------------------------------------------------------

exit 0;
