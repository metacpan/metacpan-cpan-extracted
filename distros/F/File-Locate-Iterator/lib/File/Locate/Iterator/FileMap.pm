# Copyright 2009, 2010, 2011, 2014 Kevin Ryde.
#
# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator; see the file COPYING.  Failing that, go to
# <http://www.gnu.org/licenses/>.

package File::Locate::Iterator::FileMap;
use 5.006;
use strict;
use warnings;
use Carp;

# uncomment this to run the ### lines
#use Devel::Comments;

our $VERSION = 23;

our %cache;

sub _key {
  my ($fh) = @_;
  my ($dev, $ino, undef, undef, undef, undef, undef, $size) = stat ($fh);
  return "$dev,$ino,$size,".tell($fh);
}
sub find {
  my ($class, $fh) = @_;
  return $cache{_key($fh)};
}

# return a FileMap object which is $fh mmapped
sub get {
  my ($class, $fh) = @_;

  my $key = _key($fh);
  ### cache get: "$fh, $key, size=".(-s $fh)
  return ($cache{$key} || do {
    require File::Map;
    # File::Map->VERSION('0.35'); # for binary handled properly, maybe
    File::Map->VERSION('0.38'); # for tainting
    require PerlIO::Layers;
    require Scalar::Util;

    PerlIO::Layers::query_handle ($fh, 'mappable')
        or croak "Handle not mappable";

    my $self = bless { key  => $key,
                       mmap => undef,
                     }, $class;

    my $tell = tell($fh);
    if ($tell < 0) {
      # assume if tell() doesn't work then $fh is not mmappable, or in any
      # case don't know where the current position is to map
      croak "Cannot tell() file position: $!";
    }

    # File::Map 0.38 does tainting itself
    #
    # # induce taint on the mmap -- seems to cause segvs though
    # read $fh, $self->{'mmap'}, 0;
    # use Devel::Peek;
    # Dump ($self->{'mmap'});
    #
    # # crib: must taint before mapping, doesn't work afterwards
    # require Taint::Util;
    # Taint::Util::taint($self->{'mmap'});

    File::Map::map_handle ($self->{'mmap'}, $fh, '<', $tell);
    File::Map::advise ($self->{'mmap'}, 'sequential');

    Scalar::Util::weaken ($cache{$key} = $self);
    $self;
  });
}
# return a scalar ref to the mmapped string
sub mmap_ref {
  my ($self) = @_;
  return \($self->{'mmap'});
}
sub DESTROY {
  my ($self) = @_;
  delete $cache{$self->{'key'}};
}

use constant::defer _PAGESIZE => sub {
  require POSIX;
  my $pagesize = eval { POSIX::sysconf (POSIX::_SC_PAGESIZE()) } || -1;
  return ($pagesize > 0 ? $pagesize : 1024);
};

# return the total bytes used by mmaps here plus prospective further $space
sub _total_space {
  my ($space) = @_;
  ### total space of: $space, values(%cache)
  $space = _round_up_pagesize($space);
  foreach my $self (values %cache) {
    $space += _round_up_pagesize (length (${$self->mmap_ref}));
  }
  return $space;
}
sub _round_up_pagesize {
  my ($n) = @_;

  my $pagesize = _PAGESIZE();
  return $pagesize * int (($n + $pagesize - 1) / $pagesize);
}

#-----------------------------------------------------------------------------

# return true if $fh has an ":mmap" layer
sub _have_mmap_layer {
  my ($fh) = @_;
  my $ret;
  eval {
    require PerlIO; # new in perl 5.8
    foreach my $layer (PerlIO::get_layers ($fh)) {
      if ($layer eq 'mmap') { $ret = 1; last; }
    }
  };
  return $ret;
}

# return true if mmapping $fh would be an excessive cumulative size
sub _mmap_size_excessive {
  my ($fh) = @_;
  if (File::Locate::Iterator::FileMap->find($fh)) {
    # if already mapped then not excessive
    return 0;
  }

  # in 32-bits this is 4G*(1/4)*(1/5) which is 200Mb
  require Config;
  my $limit
    = (2 ** (8 * $Config::Config{'ptrsize'}))  # eg. 2^32 bytes addr space
      * 0.25   # perhaps only 1/2 or 1/4 of it usable for data
        * 0.2; # then don't go past 1/5 of that usable space

  my $prosp = File::Locate::Iterator::FileMap::_total_space (-s $fh);
  ### mmap size limit: $limit
  ### file size: -s $fh
  ### for new total: $prosp
  return ($prosp > $limit);
}

1;
__END__

=for stopwords mmap mmaps FileMap mmapped Ryde

=head1 NAME

File::Locate::Iterator::FileMap -- shared mmaps for File::Locate::Iterator

=head1 DESCRIPTION

This is an internal part of C<File::Locate::Iterator>.  A FileMap object
holds a file mmapped by C<File::Map> and will re-use it rather than mapping
the same file a second time.

This module shouldn't exist, since C<File::Map> is in a much better position
to share read-only mmaps, and can do so across threads too.  Almost every
read-only mmap will want to share.  Straightforward cases like an mmap of a
whole file should definitely share.

=head1 SEE ALSO

L<File::Locate::Iterator>, L<File::Map>

=head1 HOME PAGE

http://user42.tuxfamily.org/file-locate-iterator/index.html

=head1 COPYRIGHT

Copyright 2009, 2010, 2011, 2014 Kevin Ryde

File-Locate-Iterator is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

File-Locate-Iterator is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
File-Locate-Iterator.  If not, see http://www.gnu.org/licenses/

=cut
