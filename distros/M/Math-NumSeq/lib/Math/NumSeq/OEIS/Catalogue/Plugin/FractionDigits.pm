# Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::OEIS::Catalogue::Plugin::FractionDigits;
use 5.004;
use strict;
use List::Util 'min', 'max'; # FIXME: 5.6 only, maybe

use vars '@ISA';
use Math::NumSeq::OEIS::Catalogue::Plugin;
@ISA = ('Math::NumSeq::OEIS::Catalogue::Plugin');

use vars '$VERSION';
$VERSION = 73;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant num_first => 21022;   # A021022 1/18
use constant num_last  => 21999;   # A021999 1/995

my %exclude = (21029 => 1,  # A021029 is not 1/25 (0.0400000...)
               21048 => 1,  # A021048 is not 1/44 (0.0227272...)
               21049 => 1,  # A021049 is not 1/45 (0.0222222...)
               21076 => 1,  # A021076 is not 1/72 (0.0138888...)
               21079 => 1,  # A021079 is not 1/75 (0.0133333...)
               21092 => 1,  # A021092 is not 1/88 (0.011363636...)
               21103 => 1,  # A021103 is not 1/99 (0.0101010101...)
               21129 => 1,  # A021129 is not 1/125
               21202 => 1,  # A021202 is not 1/198
               21229 => 1,  # A021229 is not 1/225
               21268 => 1,  # A021268 is not 1/264
               21279 => 1,  # A021279 is not 1/275
               21379 => 1,  # A021379 is not 1/375
               21503 => 1,  # A021503 is not 1/499               
               21772 => 1,  # A021772 is not 1/768
               21629 => 1,  # A021629 is not 1/625
               21829 => 1,  # A021829 is not 1/825
              );
sub anum_after {
  my ($class, $anum) = @_;
  ### anum_after(): $anum

  my $num = _anum_to_num($anum) + 1;
  ### $num
  if (($class->num_to_denominator($num) % 10) == 0
      || $exclude{$num}) {
    ### skip ...
    $num++;
  }
  if ($num > $class->num_last) {
    return undef;
  }
    ### ret: $num
  return sprintf 'A%06d', max ($num, $class->num_first);
}

sub anum_before {
  my ($class, $anum) = @_;
  ### anum_before(): $anum

  my $num = _anum_to_num($anum) - 1;
  if (($class->num_to_denominator($num) % 10) == 0
      || $exclude{$num}) {
    ### skip ...
    $num--;
  }
  if ($num <= $class->num_first) {
    return undef;
  }
  ### ret: $num
  return sprintf 'A%06d', min ($num, $class->num_last);
}

sub _anum_to_num {
  my ($anum) = @_;
  if ($anum =~ /A0*([0-9]+)/ || $anum =~ /([1-9][0-9]*)/) {
    return $1;
  } else {
    return 0;
  }
}

sub anum_to_info {
  my ($class, $anum) = @_;
  ### FractionDigits anum_to_info(): $anum

  # Math::NumSeq::FractionDigits
  # fraction=1/k radix=10 for k=11 to 995 is anum=21004+k,
  # being A021015 through A021999, though 1/11 is also A010680 and prefer
  # that one (in BuiltinTable.pm)

  my $num = _anum_to_num($anum);
  ### $num
  if (($class->num_to_denominator($num) % 10) != 0
      && ! $exclude{$num}
      && $num >= $class->num_first
      && $num <= $class->num_last) {
    return $class->make_info($num);
  } else {
    return undef;
  }
}

my @info_array;
sub info_arrayref {
  my ($class) = @_;
  if (! @info_array) {
    @info_array = map {$class->make_info($_)}
      grep {($_ % 10) != 0}
        $class->num_first .. $class->num_last;
    ### made info_arrayref: @info_array
  }
  return \@info_array;
}

sub make_info {
  my ($class, $num) = @_;
  ### make_info(): $num
  return { anum  => sprintf('A%06d', $num),
           class => 'Math::NumSeq::FractionDigits',
           parameters =>
           [ fraction => '1/'.$class->num_to_denominator($num),
             radix => 10,
           ],
         };
}

sub num_to_denominator {
  my ($class, $num) = @_;
  return ($num-21004);
}

1;
__END__

