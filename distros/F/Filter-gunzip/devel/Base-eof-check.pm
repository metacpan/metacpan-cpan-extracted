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
use Filter::Util::Call qw(filter_add filter_read);

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

  unless ($self->{'input_eof'} || length ($self->{'input'})) {
    my $status = filter_read(1);
    if (DEBUG) { print " filter_read() $status\n"; }
    if ($status < 0) {
      delete $self->{'inflator'};
      return $status;
    }
    if ($status == 0) {
      $self->{'input_eof'} = 1;
    }
    $self->{'input'} = $_;
  }

  if (! $self->{'inflator'}) {
    # inflator got to EOF, expect the same on the input
    if (! $self->{'input_eof'}) {
      carp ref($self)," spurious extra input bytes";
      $self->{'input_eof'} = 1;
      return -1;
    }
    return 0;
  }

  my $input_length = length($self->{'input'});
  my $status = $self->inflate ($self->{'input'}, $_);
  if (DEBUG) { print STDERR " inflate() $status",
                 " output ", length($_),
                   " leaving ", length($self->{'input'}), "\n"; }

  if ($status > 0) {
    if (length($_) == 0
        && $input_length == length($self->{'input'})) {
      # protect against infinite loop
      carp ref($self)," oops, inflator produced nothing and consumed nothing";
      $status = -1;

    } elsif (length($_) == 0
             && length($self->{'input'}) == 0
             && $self->{'input_eof'}) {
      # EOF on the input side but the inflator is not at EOF and has no
      # output
      carp ref($self)," incomplete input";
      $status = -1;

    } else {
      # normal data output
      # can have $_ empty here, but that's ok, there'll be another call
      # immediately
      return 1;
    }
  }

  delete $self->{'inflator'};

  if ($status == 0) {
    if ($self->{'input_eof'}) {
      # EOF on input side and EOF from inflator, so finished
      # return non-zero if final output in $_, or 0 for eof if no more
      return length($_);
    }
    # EOF from inflator, but not yet from the input
    # return $_ now so it can run etc, then if there's spurious extra the
    # carp for it will be afterwards
    return 1;
  }

  return $status;
}

1;
__END__
