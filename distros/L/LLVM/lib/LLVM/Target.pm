package LLVM::Target;
{
  $LLVM::Target::VERSION = '0.10';
}

use strict;
use warnings;

=head1 NAME

LLVM::Target - LLVM target class

=head1 VERSION

version 0.10

=head1 DESCRIPTION

A C<LLVM::Target> represents a target for a specific architecture.

=head1 METHODS

=head2 targets( )

Retrieve a list of supported targets.

=head2 name( )

Retrieve the name of the given C<LLVM::Target>.

=head2 description( )

Retrieve the description of the given C<LLVM::Target>.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of LLVM::Target
