package GCCJIT::Context;
use strict;
use warnings;

require GCCJIT::Wrapper;

sub acquire {
    gcc_jit_contextPtr::acquire();
}

=head1 NAME

GCCJIT::Context - object-oriented wrapper around libgccjit bindings.

=head1 SYNOPSYS

    use GCCJIT qw/:constants/;
    use GCCJIT::Context;

    my $ctxt = GCCJIT::Context->acquire();
    $ctxt->get_type(GCC_JIT_TYPE_INT);

=head1 DESCRIPTION

This package provides an object-oriented wrapper around libgccjit. In addition
to shorter method names, these wrappers handle the memory management tasks
remained from libgccjit (which already is very simple).

=head2 Shorter names

All libgccjit functions are available as methods on corresponding object
references.

    gcc_jit_context_get_type($ctxt, ...)

becomes:

    $ctxt->get_type(...)

=head2 Memory management

In libgccjit context objects own all allocated memory: developer needs only to
release context to free all allocated memory, and until then all pointers
produced by the library are valid.

When using this wrapper context and result objects will be freed automatically
when last reference to it is gone as usual.

Other objects, like types, functions and blocks will become invalid once context
owning them is destroyed. If any methods are called on a invalidated object,
a perl exception is thrown.

=head1 METHODS

This package contain only one method:

    GCCJIT::Context->acquire()

creates new top-level libgccjit context.

=head1 SEE ALSO

Online documentation for GCCJIT library: L<https://gcc.gnu.org/onlinedocs/gcc-5.2.0/jit/>

GCCJIT project wiki page: L<https://gcc.gnu.org/wiki/JIT>

=head1 AUTHOR

Vickenty Fesunov E<lt>cpan-gccjit@setattr.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Vickenty Fesunov.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
1;
