package Games::EternalLands::Binary::Float16;

use 5.010000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  pack_float16 unpack_float16
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Games::EternalLands::Binary::Float16', $VERSION);

1;
__END__

=head1 NAME

Games::EternalLands::Binary::Float16 - 16-bit floats as used by Eternal Lands

=head1 SYNOPSIS

  use Games::EternalLands::Binary::Float16 qw(pack_float16 unpack_float16);

  # Pack to an unsigned short (i.e. a 16-bit unsigned number)
  $short = pack_float16($float);

  # Unpack from an unsigned short
  $float = unpack_float16($short);

  # Unpack from two bytes of binary data in big-endian order
  $float = unpack_float16(unpack('n', $data));

  # Unpack from binary data in little-endian order at byte offset 40
  $float = unpack_float16(unpack('x40v', $data));

  ...

=head1 ABSTRACT

This module provides functions to pack and unpack 16-bit floating-point
numbers as used in certain game data files by Eternal Lands.

Generally the algorithms should be consistent with the half-precision
floating-point format defined by IEEE 754-2008, also know as "half" or
"binary16", but this was not tested.

=head1 FUNCTIONS

=head2 pack_float16

Takes a native floating-point number argument and returns a 16-bit
unsigned integer representing the packed half-precision number.

=head2 unpack_float16

Takes a 16-bit unsigned integer representing a packed half-precision
float and returns a native floating-point number.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Half-precision_floating-point_format>

=head1 AUTHOR

Cole Minor, C<< <coleminor at hush.ai> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 Cole Minor. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
