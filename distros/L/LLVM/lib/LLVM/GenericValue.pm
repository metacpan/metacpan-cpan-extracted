package LLVM::GenericValue;
{
  $LLVM::GenericValue::VERSION = '0.10';
}

use strict;
use warnings;

=head1 NAME

LLVM::GenericValue - LLVM generic value class

=head1 VERSION

version 0.10

=head1 DESCRIPTION

A C<LLVM::GenericValue> represents a value used by the L<LLVM::ExecutionEngine>.

=head1 METHODS

=head2 int( $type, $val )

Create an integer value of L<LLVM::Type> C<$type> and value C<$val>.

=head2 uint( $type, $val )

Create an unsigned integer value of L<LLVM::Type> C<$type> and value C<$val>.

=head2 float( $type, $val )

Create a floating-point value of L<LLVM::Type> C<$type> and value C<$val>.

=head2 to_int( )

Convert the given C<LLVM::GenericValue> back to an integer value.

=head2 to_uint( )

Convert the given C<LLVM::GenericValue> back to an usigned integer value.

=head2 to_float( $type )

Convert the given C<LLVM::GenericValue> back to a floating-point value of
L<LLVM::Type> C<$type>.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of LLVM::GenericValue
