package LLVM::Value;
{
  $LLVM::Value::VERSION = '0.10';
}

use strict;
use warnings;

=head1 NAME

LLVM::Value - LLVM value class

=head1 VERSION

version 0.10

=head1 DESCRIPTION

A C<LLVM::Value> represents an individual value in the LLVM IR.

=head1 METHODS

=head2 type( )

Retrieve the L<LLVM::Type> of the given C<LLVM::Value>.

=head2 name( [ $val_name ] )

Get the name of the given C<LLVM::Value>. If C<$val_name> is set, the name of
the value will be set to its value.

=head2 func_params( )

Retrieve the C<LLVM::Value>s of the paramenters of the given C<LLVM::Type>
representing a function.

=head2 func_append( $blk_name )

Append a L<LLVM::BasicBlock> with name C<$blk_name> to the given C<LLVM::Value>
representing a function.

=head2 global_is_constant( [ $is_constant ] )

Retrieve whether the given global C<LLVM::Value> is constant. If the boolean
value C<$is_constant> is set, the global is set to constant.

=head2 global_is_threadlocal( [ $is_threadlocal ] )

Retrieve whether the given global C<LLVM::Value> is thread local. If the boolean
value C<$is_threadlocal> is set, the global is set to constant.

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of LLVM::Value
