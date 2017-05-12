#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator.  If not, see <http://www.gnu.org/licenses/>.

__END__

      if ($use_mmap) {
        if (fileno($fh) < 0) {
          ### no fileno for fh
          $use_mmap = 0;
        } els

        } elsif (defined (my $layer
                     = File::Locate::Iterator::FileMap::_bad_layer($fh))) {
          ### bad layer: $layer
          if ($use_mmap eq '1') {
            croak "database_fh layer '$layer' no good for mmap";
          }
          $use_mmap = 0;


my %acceptable_layers = (unix   => 1,
                         stdio  => 1,
                         perlio => 1,
                         mmap   => 1);

# return the name of a layer bad for mmap, or undef if all ok
sub _bad_layer {
  my ($fh) = @_;
  my $bad_layer;
  eval {
    require PerlIO; # new in perl 5.8
    foreach my $layer (PerlIO::get_layers ($fh)) {
      if (! $acceptable_layers{$layer}) {
        ### layer no good for mmap: $layer
        $bad_layer = $layer;
        last;
      }
    }
  };
  return $bad_layer;
}


#-----------------------------------------------------------------------------
# _bad_layer()

{
  open my $fh, '<', $samp_locatedb
    or die "oops, cannot open $samp_locatedb";
  binmode($fh)
    or die "oops, cannot set binary mode";
  diag "binmode layers: ",PerlIO::get_layers($fh);
  is (File::Locate::Iterator::FileMap::_bad_layer($fh), undef,
      '_bad_layer on plain open + binmode');
}

SKIP: {
  $have_PerlIO
    or skip 'PerlIO module not available', 1;

  open my $fh, '<:crlf', $samp_locatedb
    or die "oops, cannot open $samp_locatedb with :crlf";
  diag "crlf layers: ",PerlIO::get_layers($fh);
  is (File::Locate::Iterator::FileMap::_bad_layer($fh), 'crlf',
      '_bad_layer on :crlf');
}

SKIP: {
  $have_PerlIO
    or skip 'PerlIO module not available', 1;

  open my $fh, '<:stdio', $samp_locatedb
    or die "oops, cannot open $samp_locatedb with :crlf";
  binmode($fh)
    or die "oops, cannot set binary mode";
  diag "stdio layers: ",PerlIO::get_layers($fh);
  is (File::Locate::Iterator::FileMap::_bad_layer($fh), undef,
      '_bad_layer on :stdio');
}

