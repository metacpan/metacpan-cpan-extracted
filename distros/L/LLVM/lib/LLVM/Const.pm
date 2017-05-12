package LLVM::Const;
{
  $LLVM::Const::VERSION = '0.10';
}

use strict;
use warnings;

=head1 NAME

LLVM::Const - LLVM const value class

=head1 VERSION

version 0.10

=head1 DESCRIPTION

A C<LLVM::Const> represents a constant value.

=head1 METHODS

=head2 int( $int_type, $value )

Create a new constant integer L<LLVM::Value> with value C<$value>.

=head2 real( $real_type, $value )

Create a new constant real L<LLVM::Value> with value C<$value>.

=head2 string( $value )

Create a new constant string L<LLVM::Value> with value C<$value>.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of LLVM::Const
