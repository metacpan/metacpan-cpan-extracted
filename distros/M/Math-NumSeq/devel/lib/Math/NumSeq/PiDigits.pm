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

package Math::NumSeq::PiDigits;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;
use Math::NumSeq::Base::Digits;
@ISA = ('Math::NumSeq::Base::Digits');

use Math::NumSeq 7; # v.7 for _is_infinite()
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant name => Math::NumSeq::__('Pi Digits');
use constant description => Math::NumSeq::__('Digits of Pi.');
use constant i_start => 1;

# use constant parameter_info_array =>
#   [
#    Math::NumSeq::Base::Digits->parameter_info_list,
#   ];
# 
# # cf A001203 - pi continued fraction
# #
# my @oeis_anum = (undef,
#                  undef,
#                  'A004601',  # 2
#                  'A004602',  # 3
#                  'A004603',  # 4
#                  'A004604',  # 5
#                  'A004605',  # 6
#                  'A004606',  # 7
#                  'A006941',  # 8
#                  'A004608',  # 9 
#                  'A000796',  # 10
#                  'A068436',  # 11
#                  'A068437',  # 12
#                  'A068438',  # 13
#                  'A068439',  # 14
#                  'A068440',  # 15
#                  'A062964',  # 16
#                 );
# 
# sub oeis_anum {
#   my ($self) = @_;
#   return $oeis_anum[$self->{'radix'}];
# }

sub rewind {
  my ($self) = @_;
  $self->{'i'} = 1;
  $self->{'pending'} = [3];
}
sub next {
  my ($self) = @_;
  ### PiDigits next(): $self->{'i'}
  my $i = $self->{'i'}++;
  my $value;
  unless (defined ($value = shift @{$self->{'pending'}})) {
    my $pending = $self->{'pending'};
    my $radix = $self->{'radix'};
    my $len = int($i * 1.1 + 50);
    my $pi = _bigfloat()->bpi($len);
    ### pi: "$pi"
    @$pending = (split //, substr ($pi, $i));
    splice @$pending, -20; # don't trust the last few
    $value = shift @$pending;
  }
  return ($i, $value);
}

# Note: this is "use Math::BigFloat" not "require Math::BigFloat" because
# BigFloat 1.997 does some setups in its import() needed to tie-in to the
# BigInt back-end, or something.
use constant::defer _bigfloat => sub {
  eval "use Math::BigFloat; 1" or die $@;
  return "Math::BigFloat";
};

# sub ith {
#   my ($self, $i) = @_;
#   ### PiDigits ith(): $i
#   if ($i < 0) {
#     return undef;
#   }
#   if (_is_infinite($i)) {
#     return $i;
#   }
# 
#   my $radix = $self->{'radix'};
#   my $power = 1;
#   my $len = 1;
#   my $n = 1;
#   while ($i >= $power) {
#     $i -= $power;
#     $power *= $radix;
#     $len++;
#     $n *= $radix;
#   }
# 
#   ### remainder: $i
#   ### $len
#   ### $n
# 
#   my $shift = $i % $len;
#   $n += int($i/$len);
# 
#   ### $shift
#   ### $n
# 
#   if ($self->{'endian'} eq 'big') {
#     $shift = $len-1 - $shift;
#   }
#   while ($shift-- > 0) {
#     $n = int($n/$radix);
#   }
#   return $n % $radix;
# }

1;
__END__

L<Math::NumSeq::SqrtDigits>
