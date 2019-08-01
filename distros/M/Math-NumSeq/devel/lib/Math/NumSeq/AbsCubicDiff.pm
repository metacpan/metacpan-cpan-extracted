# Copyright 2012, 2013, 2014, 2016 Kevin Ryde

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

package Math::NumSeq::AbsCubicDiff;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;
use Math::NumSeq;
use List::Util 'min';
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
# use constant description => Math::NumSeq::__('S(i) = abs(S(i-1) - S(i-2) - S(i-3))');
use constant i_start => 1;
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;
use constant parameter_info_array =>
  [
   {
    name        => 'initial_values',
    type        => 'string',
    share_key   => 'integer_triple',
    default     => '1,1,2',
    width       => 8,
    # description => Math::NumSeq::__('...'),
   },
  ];

sub values_min {
  my ($self) = @_;
  return 0;  # always 0 ?

  #  return gcd(_initial_values($self));
}


my %oeis_anum = ('1,1,2' => 'A080096',
                 '1,1,6' => 'A079624',
                 '1,1,4' => 'A079623',
                 '0,0,1' => 'A088226',
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{join(',',_initial_values($self))};
}
sub _initial_values {
  my ($self) = @_;
  my ($f0, $f1, $f2)
    = grep {$_ ne ''} split /\D/, $self->{'initial_values'}, 3;
  return ($f0||0, $f1||0, $f2||0);
}

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  ($self->{'f0'},
   $self->{'f1'},
   $self->{'f2'}) = _initial_values($self);
 }
sub next {
  my ($self) = @_;
  ### AbsCubicDiff next(): "i=$self->{'i'}  $self->{'f0'} $self->{'f1'} $self->{'f2'}"
  (my $ret,
   $self->{'f0'},
   $self->{'f1'},
   $self->{'f2'})
   = ($self->{'f0'},
      $self->{'f1'},
      $self->{'f2'},
      abs($self->{'f2'} - $self->{'f1'} - $self->{'f0'}));
  ### ret: "$ret"
  return ($self->{'i'}++, $ret);
}

1;
__END__
