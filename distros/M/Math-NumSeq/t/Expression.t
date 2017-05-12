#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2016 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
plan tests => 12;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

use Math::NumSeq::Expression;

# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 72;
  ok ($Math::NumSeq::Expression::VERSION, $want_version,
      'VERSION variable');
  ok (Math::NumSeq::Expression->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::NumSeq::Expression->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::NumSeq::Expression->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------

# Language::Expr 0.29 has some dodginess where about redefined func 'with'
# from Role::Tiny and Role::Tiny::With.  Dunno who's to blame but for now
# don't make it fatal to MyTestHelpers::nowarnings().
eval {
  my $old_warner = $SIG{'__WARN__'};
  local $SIG{'__WARN__'} = sub {
    my ($str) = @_;
    if ($str =~ /::with redefined/) {
      print $str;
    } else {
      $old_warner->($str);
    }
  };
  my $seq = Math::NumSeq::Expression->new (expression_evaluator => 'LE',
                                           expression => '123');
};

{
  my $info = Math::NumSeq::Expression->parameter_info_hash->{'expression_evaluator'};
  my $good = 1;
  foreach my $evaluator (@{$info->{'choices'}}) {
    my $seq = Math::NumSeq::Expression->new (expression_evaluator => $evaluator,
                                             expression => '123');
    my $got = join(',',$seq->next);
    if ($got ne '0,123') {
      MyTestHelpers::diag ("expression_evaluator $evaluator got $got");
      $good = 0;
    }
  }
  ok ($good, 1);
}

#------------------------------------------------------------------------------
# Perl expressions

{
  my $seq = Math::NumSeq::Expression->new (expression => '2*i');
  ok (join(',',map {$seq->next} 1,2,3), '0,0,1,2,2,4');
}
{
  my $seq = Math::NumSeq::Expression->new (expression => 'i*2');
  ok (join(',',map {$seq->next} 1,2,3), '0,0,1,2,2,4');
}
{
  my $seq = Math::NumSeq::Expression->new (expression => '2*$i');
  ok (join(',',map {$seq->next} 1,2,3), '0,0,1,2,2,4');
}


#------------------------------------------------------------------------------
# LE expression

{
  my $info = Math::NumSeq::Expression->parameter_info_hash->{'expression_evaluator'};
  my $choices_aref = $info->{'choices'};
  my $have_LE = grep {$_ eq 'LE'} @$choices_aref;

  my ($seq, $i,$value);
  if ($have_LE) {
    $seq = Math::NumSeq::Expression->new (expression => '2*$i + 7',
                                          expression_evaluator => 'LE');
    ($i,$value) = $seq->next;
  }
  skip (! $have_LE, $i,     0);
  skip (! $have_LE, $value, 7);

  if ($have_LE) {
    ($i,$value) = $seq->next;
  }
  skip (! $have_LE, $i,     1);
  skip (! $have_LE, $value, 9);
}


#------------------------------------------------------------------------------
exit 0;


