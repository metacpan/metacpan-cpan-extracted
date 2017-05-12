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

package Filter::Gunzip;
use strict;
use warnings;
use Carp;
use Filter::Util::Call;
use Compress::Zlib;

our $VERSION = 6;

use constant DEBUG => 1;

sub import {
  my ($class) = @_;
  filter_add ($class->new);
}
   
sub new {
  my ($class) = @_;
  my ($inf, $zerr) = inflateInit
    (-WindowBits => MAX_WBITS() + WANT_GZIP_OR_ZLIB());
  $inf or croak "Gunzip cannot create inflator: $zerr";
  return bless { inf => $inf, input => '' }, $class;
}

sub filter {
  my ($self) = @_;
  if (DEBUG) { print STDERR "filter\n"; }

  unless ($self->{'input_eof'} || length ($self->{'input'})) {
    $_ = '';
    my $status = filter_read(5);
    if (DEBUG) { print " filter_read() $status\n"; }
    if ($status < 0) {
      delete $self->{'inf'};
      return ($self->{'final_status'} = $status);
    }
    if ($status == 0) {
      $self->{'input_eof'} = 1;
    }
    $self->{'input'} = $_;
  }

  my $inf = $self->{'inf'} || do {
    if (! $self->{'input_eof'}) {
      carp "Gunzip spurious extra input bytes";
      $self->{'input_eof'} = 1;
      $self->{'final_status'} = -1;
    }
    return $self->{'final_status'};
  };

  my ($output, $zerr) = $inf->inflate($_);
  if (DEBUG) { print "   inflate() \"$zerr\" leaving ",length($_),"\n"; }

  if ($zerr == Z_STREAM_END) {
    delete $self->{'inf'};
    $self->{'final_status'} = 0;
    if ($self->{'input_eof'}) {
      # 0 for eof if no output
      return length($_);
    }
    # return this output, next call will check for input eof
    return 1;
  }

  if ($zerr == Z_OK) {
    if ($self->{'input_eof'}) {
      # got to EOF on filter_read(), but $inf not at Z_STREAM_END
      carp "Gunzip incomplete input";
      delete $self->{'inf'};
      return ($self->{'final_status'} = -1);
    }
    # might have empty string $output here, but that's ok, we'll be called
    # again immediately
    return 1;
  }

  carp "Gunzip error: $zerr";
  delete $self->{'inf'};
  return ($self->{'final_status'} = -1);
}

1;
__END__



#         require POSIX;
#         require Scalar::Util;
#         $! = Scalar::Util::dualvar (POSIX::EINVAL(),
#                                     'Gunzip spurious extra input bytes');
