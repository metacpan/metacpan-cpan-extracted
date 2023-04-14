=head1 NAME

IO::ExplicitHandle - force I/O handles to be explicitly specified

=head1 SYNOPSIS

    use IO::ExplicitHandle;

    no IO::ExplicitHandle;

=head1 DESCRIPTION

This module provides a lexically-scoped pragma that prohibits I/O
operations that implicitly default to an I/O handle determined at
runtime.  For example, C<print
123> implicitly uses the "currently selected" I/O handle (controlled
by L<select|perlfunc/select>).  Within the context of the pragma, I/O
operations must be explicitly told which handle they are to operate on.
For example, C<print STDOUT 123> explicitly uses the program's standard
output stream.

The affected operations are those that use either the "currently selected"
I/O handle or the "last read" I/O handle.
The affected operations that use the "currently selected" I/O handle are
L<print|perlfunc/print>, L<printf|perlfunc/printf>, L<say|perlfunc/say>,
L<close|perlfunc/close>, L<write|perlfunc/write>, and the magic variables
L<$E<verbar>|perlvar/$E<verbar>>, L<$^|perlvar/$^>, L<$~|perlvar/$~>,
L<$=|perlvar/$=>, L<$-|perlvar/$->, and L<$%|perlvar/$%>.  The affected
operations that use the "last read" I/O handle are L<eof|perlfunc/eof>,
L<tell|perlfunc/tell>, and the magic variable L<$.|perlvar/$.>.

One form
of the L<..|perlop/..> operator can implicitly read L<$.|perlvar/$.>,
but it cannot be reliably distinguished at compile time from the more
common list-generating form, so it is not affected by this module.

The L<select|perlfunc/select> function returns the "currently
selected" I/O handle, and similarly the magic variable
L<${^LAST_FH}|perlvar/${^LAST_FH}> refers to the "last read" I/O handle.
Such explicit retrieval of the I/O handles to which some operations
default isn't itself considered an operation on the handle, and so is
not affected by this module.

The L<readline|perlfunc/readline> function when called without
arguments, and its syntactic sugar alias C<< <> >>, default to the
C<ARGV> I/O handle.  Because this is a fixed default, rather than using
a hidden runtime variable, it is considered explicit enough, and so is
not affected by this module.  Relatedly, when the L<eof|perlfunc/eof>
function is called with an empty parenthesised argument list (as opposed
to calling it with no parentheses), it performs a unique operation
which is concerned with the C<ARGV> I/O handle but is not the same
as C<eof(ARGV)>.  This operation doesn't amount to defaulting an I/O
handle argument at all, and is also not affected by this module.
Likewise, the C<<< <<>> >>> operator performs a unique operation on the
C<ARGV> handle, and is also not affected by this module.

=cut

package IO::ExplicitHandle;

{ use 5.006; }
use Lexical::SealRequireHints 0.012;
use warnings;
use strict;

our $VERSION = "0.002";

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 PACKAGE METHODS

=over

=item IO::ExplicitHandle->import

Turns on the I/O handle stricture in the lexical environment that is
currently compiling.

=item IO::ExplicitHandle->unimport

Turns off the I/O handle stricture in the lexical environment that is
currently compiling.

=back

=head1 BUGS

The L<..|perlop/..> operator decides only at runtime whether it will
read from L<$.|perlvar/$.>, and hence implicitly use the "last read"
I/O handle.  It does this if called in scalar context.  If the same
expression is called in list context, it generates a list of numbers,
unrelated to L<$.|perlvar/$.>.  This semantic overloading prevents the
problematic use of L<..|perlop/..> being detected at compile time.

=head1 SEE ALSO

L<strict>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2012, 2017, 2023 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
