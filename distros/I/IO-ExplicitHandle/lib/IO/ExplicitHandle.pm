=head1 NAME

IO::ExplicitHandle - detect implicit I/O handles when compiling

=head1 SYNOPSIS

	use IO::ExplicitHandle;

	no IO::ExplicitHandle;

=head1 DESCRIPTION

This module provides a lexically-scoped pragma that prohibits I/O
operations that use an implicit default I/O handle.  For example, C<print
123> implicitly uses the "currently selected" I/O handle (controlled
by L<select|perlfunc/select>).  Within the context of the pragma, I/O
operations must be explicitly told which handle they are to operate on.
For example, C<print STDOUT 123> explicitly uses the program's standard
output stream.

The affected operations that use the "currently selected" I/O handle are
L<print|perlfunc/print>, L<printf|perlfunc/printf>, L<say|perlfunc/say>,
L<close|perlfunc/close>, L<write|perlfunc/write>, and the magic variables
L<$E<verbar>|perlvar/$E<verbar>>, L<$^|perlvar/$^>, L<$~|perlvar/$~>,
L<$=|perlvar/$=>, L<$-|perlvar/$->, and L<$%|perlvar/$%>.  The affected
operations that use the "last read" I/O handle are L<eof|perlfunc/eof>,
L<tell|perlfunc/tell>, and the magic variable L<$.|perlvar/$.>.  One form
of the L<..|perlop/..> operator can implicitly read L<$.|perlvar/$.>,
but it cannot be reliably distinguished at compile time from the more
common list-generating form, so it is not affected by this module.

=cut

package IO::ExplicitHandle;

{ use 5.006; }
use Lexical::SealRequireHints 0.007;
use warnings;
use strict;

our $VERSION = "0.000";

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

Copyright (C) 2012 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
