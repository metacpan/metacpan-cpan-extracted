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

package Math::NumSeq::PiBits;
use 5.004;
use strict;
use Carp;

use vars '$VERSION', '@ISA';
$VERSION = 72;
use Math::NumSeq;
@ISA = ('Math::NumSeq');


# uncomment this to run the ### lines
# use Smart::Comments;

use constant name => Math::NumSeq::__('Pi Bits');
use constant description => Math::NumSeq::__('Pi 3.141529... written out in binary.');
use constant values_min => 0;
use constant characteristic_increasing => 1;

# A004601 to A004608 - base 2 to 9
# A000796 - base 10
# A068436 to A068440 - base 11 to 15
# A062964 - base 16
sub new {
  my $self = shift->SUPER::new (file => 'pi', # default
                                @_);
  _open_fh($self);  # check file exists
  return $self;
}

sub _open_fh {
  my ($self) = @_;
  require Compress::Zlib;
  my $basename = $self->{'file'};
  foreach my $dir (@INC) {
    if (my $fh = Compress::Zlib::gzopen("$dir/Math/NumSeq/$basename.gz", "r")) {
      return $fh;
    }
  }
  croak "Oops, $basename.gz not found";
}

sub rewind {
  my ($self) = @_;
  $self->{'buf'} = '';
  $self->{'i'} = $self->i_start;
  $self->{'n'} = 0;

  # gzseek() won't go backwards ...
  $self->{'gz'} = _open_fh($self);
}

sub next {
  my ($self) = @_;

  if ($self->{'i'} >= length($self->{'buf'})) {
    if ($self->{'gz'}->gzread($self->{'buf'}) <= 0) {
      return;  # EOF
    }
    $self->{'i'} = $self->i_start;
  }
  my $i = $self->{'i'}++;
  return ($i, $self->{'n'} += ord(substr($self->{'buf'},$i,1)));
}

1;
__END__

