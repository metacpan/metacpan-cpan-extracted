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

package Math::NumSeq::Base::File;
use 5.004;
use strict;
use warnings;

use vars '$VERSION', '@ISA';
$VERSION = 74;
use Math::NumSeq;
@ISA = ('Math::NumSeq');


# uncomment this to run the ### lines
#use Smart::Comments;

our %filetemp;

# return object, or undef if cannot satisfy requested 'hi'
sub new {
  my $class = shift;
  ### Values File new(): @_
  my $self = bless { file_i => 0,
                     @_ }, $class;

  my $package = $self->{'package'};
  my $options = $self->{'options'};
  if (defined $options) {
    $options = "--$options";
  } else {
    $options = '';
  }
  my $key = "$package--$options";

  if (my $filetemp = $filetemp{$key}) {
    ### filename: $filetemp->filename
    if (open my $fh, '<', $filetemp->filename) {
      if (my ($hi) = <$fh>) {
        chomp $hi;
        ### $hi
        if ($hi >= $self->{'hi'}) {
          $self->{'hi'} = $hi;
          $self->{'fh'} = $fh;
          my $bytes = ($hi+1 + 7) >> 3;
          seek $fh, 32+1+$bytes, 0 or die;
          ### $self
          return $self;
        }
      }
    }
  }
  return undef;
}

sub rewind {
  my ($self) = @_;
  $self->{'file_i'} = 0;
}
sub next {
  my ($self) = @_;
  ### Values File next(): $self
  if (defined (my $n = readline ($self->{'fh'}))) {
    chomp $n;
    return ($self->{'file_i'}++, $n);
  } else {
    return;
  }
}

sub pred {
  my ($self, $n) = @_;
  my $pos = 32 + ($n>>3);
  seek $self->{'fh'}, $pos, 0;
  read $self->{'fh'}, my $buf, 1 or die;
  return vec($buf, $n&7,1);
}

# sub name            { return $_[0]->{'package'}->name        }
sub characteristic {
  my $self = shift;
  return $self->{'package'}->characteristic(@_);
}
sub description          { return $_[0]->{'package'}->description }
sub parameter_info_array { return $_[0]->{'package'}->parameter_info_array  }
sub parameter_info_hash  { return $_[0]->{'package'}->parameter_info_hash  }


1;
__END__
