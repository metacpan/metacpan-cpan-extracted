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

package Filter::Gunzip::Base;
use strict;
use warnings;
use Carp;
use Filter::Util::Call qw(filter_add filter_read filter_del);

our $VERSION = 6;

use constant DEBUG => 0;

# A little trouble is taken to discard $self->{'inflator'} once no longer
# needed, since bzip2 supposedly uses either 2.5Mb or 4Mb for decompressing.

sub import {
  my ($class) = @_;
  my $self = $class->new;
  # avoid Filter::Util::Call 1.37 re-blessing the object
  $class = ref $self;
  filter_add ($self);
  bless $self, $class;
}

sub new {
  my $class = shift;
  return bless { input => '', @_ }, $class;
}

sub filter {
  my ($self) = @_;
  if (DEBUG) { print STDERR "$self\n"; }

  if (! $self->{'inflator'}) {
    # inflator got to EOF, remove self and return remaining $self->{'input'}
    filter_del();
    if ($self->{'input_eof'}) {
      return 0;
    } else {
      $_ = delete $self->{'input'};
      return 1;
    }
  }

  if (! $self->{'input_eof'} && ! length ($self->{'input'})) {
    my $status = filter_read(4096);
    if (DEBUG) { print " filter_read() $status\n"; }
    if ($status < 0) { return $status; }
    if ($status == 0) {
      $self->{'input_eof'} = 1;
    } else {
      $self->{'input'} = $_;
    }
  }

  my $input_before = length($self->{'input'});
  my $status = $self->inflate ($self->{'input'}, $_);
  if (DEBUG) { print STDERR " inflate() $status",
                 " output ", length($_),
                   " leaving ", length($self->{'input'}), "\n"; }

  if ($status == 0) {
    # inflator at eof, return final output now, next call will consider
    # balance of $self->{'input'}
    delete $self->{'inflator'};
    return 1;
  }

  if ($status > 0) {
    if (length($_) == 0) {
      if ($input_before == length($self->{'input'})) {
        # protect against infinite loop
        carp ref($self),
          " oops, inflator produced nothing and consumed nothing";
        return -1;
      }
      if ($self->{'input_eof'}) {
        # EOF on the input side (and $self->{'input_eof'} is only set when
        # $self->{'input'} is empty) but the inflator is not at EOF and has
        # no further output at this point
        carp ref($self)," incomplete input";
        return -1;
      }
    }
  }
  # at this point either
  #   - $status>0 for normal data output (possibly empty, but if so there'll
  #     be another call immediately)
  #   - $status<0 for error from $self->inflate()
  return $status;
}

1;
__END__
