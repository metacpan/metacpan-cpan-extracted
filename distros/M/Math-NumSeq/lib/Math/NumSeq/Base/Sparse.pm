# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::Base::Sparse;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant characteristic_sparse => 1;

sub new {
  my $class = shift;
  ### Sparse new() ...
  return $class->SUPER::new (pred_array => [],
                             pred_hash  => {},
                             pred_value => -1,
                             @_);
}
sub ith {
  my ($self, $i) = @_;

  if (_is_infinite($i)) {
    return $i;
  }

  ### pred_array last: $#{$self->{'pred_array'}}
  while ($#{$self->{'pred_array'}} < $i) {
    _extend ($self);
  }
  ### pred_array: $self->{'pred_array'}
  return $self->{'pred_array'}->[$i];
}

sub pred {
  my ($self, $value) = @_;
  ### Sparse pred(): $value
  if (_is_infinite($value)) {
    return 0;
  }
  while ($self->{'pred_value'} < $value
         || $self->{'pred_value'} < 10) {
    _extend ($self);
  }
  ### pred_hash: $self->{'pred_hash'}
  ### Sparse pred result: exists($self->{'pred_hash'}->{$value})
  return exists($self->{'pred_hash'}->{$value});
}

sub _extend {
  my ($self) = @_;
  ### Sparse _extend()
  my $iter = ($self->{'pred_iter'} ||= do {
    ### Sparse create pred_iter
    my $class = ref $self;
    my $it = $class->new (%$self);
    # while ($self->{'pred_value'} < 10) {
    #   my ($i, $pred_value) = $it->next;
    #   $self->{'pred_hash'}->{$self->{'pred_value'}=$pred_value} = undef;
    # }
    # ### $it
    $it
  });
  my ($i, $value) = $iter->next;
  ### $i
  ### $value
  $self->{'pred_value'} = $value;
  $self->{'pred_array'}->[$i - $self->i_start] = $value;
  $self->{'pred_hash'}->{$value} = undef;
}

1;
__END__
