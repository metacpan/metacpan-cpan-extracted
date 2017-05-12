package Games::EternalLands::Binary::Unitvec16;

use 5.010000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  pack_unitvec16 unpack_unitvec16
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Games::EternalLands::Binary::Unitvec16', $VERSION);

use Carp qw(croak);

sub pack_unitvec16 {
  croak "Expected array reference argument." if ref($_[0]) ne 'ARRAY';
  croak "Array must contain at least 3 elements." if @{$_[0]} < 3;
  return _pack_unitvec16($_[0]);
}

sub unpack_unitvec16 {
  return _unpack_unitvec16($_[0]);
}

1;
__END__

=head1 NAME

Games::EternalLands::Binary::Unitvec16 - 16-bit quantized unit vectors as used by Eternal Lands

=head1 SYNOPSIS

  use Games::EternalLands::Binary::Unitvec16 qw(pack_unitvec16 unpack_unitvec16);

  # Pack to an unsigned short (i.e. a 16-bit unsigned number)
  $short = pack_unitvec16([1, 0, 0]);

  # Unpack from an unsigned short
  $vector = unpack_unitvec16($short);

  ...

=head1 ABSTRACT

This module provides functions to pack and unpack 16-bit quantized
unit vectors as used in certain game data files by Eternal Lands.

=head1 FUNCTIONS

=head2 pack_unitvec16

Takes a reference to an array of length 3 and returns a packed 16-bit
integer.

=head2 unpack_unitvec16

Takes a 16-bit integer and returns a reference to an array with 3 
floating-point elements in it.

=head1 NOTE

Be sure to use the correct byte order if you are reading the 16-bit
integers from a file or network packets. For Eternal Lands data, this
will almost certainly be in little-endian byte order. So if your
machine is not little-endian, remember to convert the data
appropriately (see L<pack>).

=head1 SEE ALSO

L<http://www.gamedev.net/page/resources/_/technical/math-and-physics/higher-accuracy-quantized-normals-r1252>

=head1 AUTHOR

Cole Minor, C<< <coleminor at hush.ai> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 Cole Minor. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
