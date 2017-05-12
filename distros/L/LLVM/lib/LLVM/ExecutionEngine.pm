package LLVM::ExecutionEngine;
{
  $LLVM::ExecutionEngine::VERSION = '0.10';
}

use strict;
use warnings;

=head1 NAME

LLVM::ExecutionEngine - LLVM execution engine class

=head1 VERSION

version 0.10

=head1 DESCRIPTION

A C<LLVM::ExecutionEngine> represents a LLVM JIT engine.

=head1 METHODS

=head2 new( $mod )

Create a new C<LLVM::ExecutionEngine> for the L<LLVM::Module> C<$mod>.

=head2 run_func( $func [, $arg ... ] )

Run the function C<$func> (of type L<LLVM::Value>) with the given arguments of
type L<LLVM::GenericValue>.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of LLVM::ExecutionEngine
