package LLVM::Module;
{
  $LLVM::Module::VERSION = '0.10';
}

use strict;
use warnings;

=head1 NAME

LLVM::Module - LLVM module class

=head1 VERSION

version 0.10

=head1 DESCRIPTION

A C<LLVM::Module> is the top-level container for all the LLVM IR objects.

=head1 METHODS

=head2 new( $id )

Create a new C<LLVM::Module> given a string representing its id (name).

=head2 add_func( $func_name, $func_type )

Add a function named C<$func_name> with L<LLVM::Type> C<$func_type>.

=head2 get_func( $func_name )

Retrieve the L<LLVM::Value> corresponding to the given function.

=head2 del_func( $func )

Delete the given L<LLVM::Value> representing a function.

=head2 add_global( $global_name, $global_type )

Add a global variable named C<$global_name> with L<LLVM::Type> C<$global_type>.

=head2 get_global( $global_name )

Retrieve the L<LLVM::Value> corresponding to the given global variable.

=head2 del_global( $global )

Delete the given L<LLVM::Value> representing a global variable.

=head2 dump( )

Dump the compiled module to C<STDERR> (useful for debug).

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of LLVM::Module
