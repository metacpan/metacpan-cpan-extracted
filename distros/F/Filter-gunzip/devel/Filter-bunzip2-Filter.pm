# Copyright 2010, 2011, 2013, 2014 Kevin Ryde

# This file is part of Filter-gunzip.
#
# Filter-gunzip is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Filter-gunzip is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Filter-gunzip.  If not, see <http://www.gnu.org/licenses/>.



package Filter::Bunzip2;
use 5.005;
use strict;
use warnings;
use Carp;
use Filter::Util::Call;
use Compress::Raw::Bzip2;

# uncomment this to run the ### lines
#use Smart::Comments;

use vars '$VERSION';
$VERSION = 6;

# libbunzip2 supposedly uses either 4Mb or 2.5Mb for decompressing, so an
# effort is made here to turf the inflator as soon as no longer needed

# Filter::Util::Call 1.37 filter_add() rudely re-blesses the object into the
# callers package.  Doesn't affect plain use here, but a subclass would want
# to fix it up again.
#
sub import {
  my ($class) = @_;
  filter_add ($class->new);
}

sub new {
  my ($class) = @_;

  # use less 'memory';
  # my $small = (less->can('of') && less->of('memory') ? 1 : 0);
  ### Bunzip2 small=$small

  my ($inf, $bzerr) = Compress::Raw::Bunzip2->new
    (0,     # appendOutput
     1,     # consumeInput
     1,     # small
     0,     # verbosity
     1);    # limitOutput
  $inf or croak "Bunzip2 cannot create inflator: $bzerr";
  #### DispStream: Compress::Raw::Bunzip2::DispStream($inf)

  return bless { inflator => $inf,
                 input    => '',
                 @_ }, $class;
}

sub filter {
  my ($self) = @_;
  ### Bunzip2

  if (! $self->{'inflator'}) {
    # inflator got to EOF, remove self and return remaining $self->{'input'}
    filter_del();
    if ($self->{'input_eof'}) {
      return 0;
    } else {
      $_ = delete $self->{'input'};
      ### return remaining input: $_
      return 1;
    }
  }

  # get some input data, if haven't seen input eof and if don't already have
  # some data to use
  #
  if (! $self->{'input_eof'} && ! length ($self->{'input'})) {
    my $status = filter_read(4096);  # input block size
    ### filter_read(): $status
    if ($status < 0) {
      delete $self->{'inf'};
      return ($self->{'final_status'} = $status);
    }
    if ($status == 0) {
      $self->{'input_eof'} = 1;
    }
    $self->{'input'} = $_;
  }

  my $input_len_before = length($self->{'input'});
  my $bzerr = $self->{'inflator'}->inflate ($self->{'input'}, $_);
  ### bzinflate: $bzerr+0, "$bzerr"
  ### output len: length($_)
  ### leaving input len: length($self->{'input'})
  if ($zerr == Z_STREAM_END) {
    # inflator at eof, return final output now, next call will consider
    # balance of $self->{'input'}
    delete $self->{'inflator'};
    #### return final inflate: $_
    return 1;
  }

  if ($bzerr == BZ_STREAM_END) {
    # inflator at eof, return final output now, next call will consider
    # balance of $self->{'input'}
    delete $self->{'inflator'};
    #### return final inflate: $_
    return 1;
  }

  my $status;
  if ($bzerr == BZ_OK) {
    if (length($_) == 0) {
      if ($input_len_before == length($self->{'input'})) {
        # protect against infinite loop
        carp __PACKAGE__,
          ' oops, inflator produced nothing and consumed nothing';
        return -1;
      }
      if ($self->{'input_eof'}) {
        # EOF on the input side (and $self->{'input_eof'} is only set when
        # $self->{'input'} is empty) but the inflator is not at EOF and has
        # no further output at this point
        carp __PACKAGE__," incomplete input";
        return -1;
      }
    }
    # it's possible $_ output is empty at this point, but if so there'll be
    # another call immediately
    #### return continuing: $_
    return 1;
  }

  carp __PACKAGE__," error: $zerr";
  return -1;
}

1;
__END__



#         require POSIX;
#         require Scalar::Util;
#         $! = Scalar::Util::dualvar (POSIX::EINVAL(),
#                                     'Bunzip2 spurious extra input bytes');
