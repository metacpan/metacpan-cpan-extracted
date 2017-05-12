#!/usr/bin/perl

# Copyright 2012, 2013 Kevin Ryde

# This file is part of Math-NumSeq-Alpha.
#
# Math-NumSeq-Alpha is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq-Alpha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq-Alpha.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Lingua::Any::Numbers;
use Math::NumSeq::AlphabeticalLength;

# use Smart::Comments;



{
  # Dutch A090589
  require Lingua::Any::Numbers;
  require Math::NumSeq::OEIS::File;
  my $seq = Math::NumSeq::OEIS::File->new(anum=>'A090589');
  my $numbers = Lingua::NL::Numbers->new;
  my $last_i = 0;
  while (my ($i,$value) = $seq->next) {
    my $str = Lingua::Any::Numbers::to_string($i,'NL');
    $str =~ s/ //g;
    my $got = length($str);
    if ($got != $value) {
      print "$i  got=$got oeis=$value\n";
    }
    $last_i = $i;
  }
  print "end $last_i\n";
  exit 0;
}

{
  # cycles
  require Math::NumSeq::AlphabeticalLength;
  my $langs = Math::NumSeq::AlphabeticalLength->parameter_info_hash->{'lang'}->{'choices'};

  foreach my $lang (@$langs) {
    foreach my $number_type ('cardinal','ordinal') {
      printf "%3s %8s  ", $lang, $number_type;
      my $seq = Math::NumSeq::AlphabeticalLength->new
        (number_type => $number_type,
         lang => $lang);
      foreach my $i ($seq->i_start .. 500) {
        my $len = $seq->ith($i) // next;
        if ($len == $i) {
          next;
        }
        my $len2 = $seq->ith($len) // next;
        if ($len2 == $i) {
          print " $i-$len-$len2";
        }
      }
      print "\n";
    }
  }
  exit 0;
}

{
  # numbers which are their own length
  require Math::NumSeq::AlphabeticalLength;
  my $langs = Math::NumSeq::AlphabeticalLength->parameter_info_hash->{'lang'}->{'choices'};

  foreach my $lang (@$langs) {
    foreach my $number_type ('cardinal','ordinal') {
      printf "%3s %8s  ", $lang, $number_type;
      my $seq = Math::NumSeq::AlphabeticalLength->new
        (number_type => $number_type,
         lang => $lang);
      foreach my $i ($seq->i_start .. 200) {
        my $len = $seq->ith($i) // next;
        if ($len == $i) {
          print " $i";
        }
      }
      print "\n";
    }
  }
  exit 0;
}


# got  4,3,2,3,4,3,3,3,3,3,3,4,4,7,7,6,6,7,5,6,5,8,7,8,9,8,8,8,8,8,7,10,9,10,11,10,10,10,10,10,6,9,8,9,10,9,9,9,9,9,6,9,8,9,10,9,9,9,9,9,6,9,8,9,10,9,9,9,9,9,7,10,9,10,11,10,10,10,10,10,4,7,6,7,8,7,7,7,7,7,6
# want 4,3,3,3,4,3,3,3,4,3,3,4,4,7,7,6,6,7,5,6,5,8,8,8,9,8,8,8,9,8,7,10,10,10,11,10,10,10,11,10,6,9,9,9,10,9,9,9,10,9,6,9,9,9,10,9,9,9,10,9,6,9,9,9,10,9,9,9,10,9,7,10,10,10,11,10,10,10,11,10,5,8,8,8,9,8,8,8,9,8,6

# 1 ett =3[utf]     f\x{00c3}\x{00b6}rsta =7[utf]
# 2 tv\x{00c3}\x{00a5} =4[utf]     andra =5[utf]
# 3 tre =3[utf]     tredje =6[utf]
# 4 fyra =4[utf]     fj\x{00c3}\x{00a4}rde =7[utf]
# 5 fem =3[utf]     femte =5[utf]


{
  require Encode;
  my $printenc = 'ascii';
  my @langs = Lingua::Any::Numbers::available();
  @langs = sort @langs;
  print "count $#langs\n";
  foreach my $lang (@langs) {
    print "$lang\n";

    foreach my $i (1 .. 185) {
      my $str = Lingua::Any::Numbers::to_string($i,$lang);
      my $ord = Lingua::Any::Numbers::to_ordinal($i,$lang);
      $str //= '[undef]';
      $ord //= '[undef]';
      my $strlen = length($str);
      my $ordlen = length($ord);
      my $str8 = (utf8::is_utf8($str) ? 'utf' : 'bytes');
      my $ord8 = (utf8::is_utf8($ord) ? 'utf' : 'bytes');
      $str = Encode::encode($printenc,$str,Encode::FB_PERLQQ());
      $ord = Encode::encode($printenc,$ord,Encode::FB_PERLQQ());
      print "$i $str =${strlen}[$str8]     $ord =${ordlen}[$ord8]\n";
    }
    print "\n";
  }
  exit 0;
}

{
  require Lingua::SV::Numbers;
  require Encode;
  foreach my $i (1 .. 5) {
    my $str = Lingua::SV::Numbers::num2sv($i);
    my $ord = Lingua::SV::Numbers::num2sv_ordinal($i);
    $str //= '[undef]';
    $ord //= '[undef]';
    my $strlen = length($str);
    my $ordlen = length($ord);
    my $str8 = (utf8::is_utf8($str) ? 'utf' : 'bytes');
    my $ord8 = (utf8::is_utf8($ord) ? 'utf' : 'bytes');
    $str = Encode::encode('latin-1',$str,Encode::FB_PERLQQ());
    $ord = Encode::encode('latin-1',$ord,Encode::FB_PERLQQ());
    print "$i $str=$strlen$str8    $ord=$ordlen$ord8\n";
  }
  exit 0;
}


{
  my @d = (1, 3, 3, 2, 0, 1, 3, 2, 2, 1, 3, 4, 4, 3, 3, 3, 3, 2, 3, 3, 4, 2, 2, 5,
           4, 4, 2, 5, 5, 4, 4, 2, 2, 5, 4, 4, 2, 5, 5, 4, 2, 3, 3, 3, 2, 2, 3, 3,
           3, 2, 2, 3, 3, 3, 2, 2, 3, 3, 3, 2, 2, 3, 3, 3, 2, 2, 3, 3, 3, 2, 3, 4,
           4, 5, 5, 5, 3, 5, 5);

  require Math::NumSeq::AlphabeticalLengthSteps;
  my $number_type = 'cardinal';
  my $ll = Math::NumSeq::AlphabeticalLength->new
    (number_type => $number_type);
  my $seq = Math::NumSeq::AlphabeticalLengthSteps->new
    (number_type => $number_type);
  foreach my $i (0 .. $#d) {
    my $calc = $seq->ith($i);
    my $diff = ($calc != $d[$i] ? '  ***' : '');
    my $len = $ll->ith($i);
    print "$i=$len   $calc $d[$i]$diff\n";
  }
  exit 0;
}



{
  # IT -- no get_ordinate()
  require Encode;
  require Lingua::IT::Numbers;
  foreach my $i (1 .. 5) {
    my $str = Lingua::IT::Numbers::number_to_it($i);
    my $ord = Lingua::IT::Numbers->get_ordinate($i);
    $str //= '[undef]';
    $ord //= '[undef]';
    $str = Encode::encode('latin-1',$str,Encode::FB_PERLQQ());
    $ord = Encode::encode('latin-1',$ord,Encode::FB_PERLQQ());
    print "$i $str    $ord\n";
  }
  exit 0;
}


