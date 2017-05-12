package Devel::TypeCheck::Sym2type;

use strict;
use Devel::TypeCheck::Type;
use Devel::TypeCheck::Util;

=head1 NAME

Devel::TypeCheck::Sym2type - abstract parent to symbol table types.

=head1 SYNOPSIS

Devel::TypeCheck::Type is an abstract class and should not be
instantiated directly.  This defines the interface for symbol table
types, for keeping track of types in a symbol table.

=head1 DESCRIPTION

=over 4

=cut

=item B<new>

Create a new symbol to type table.

=cut
sub new {
    my ($name) = @_;
    return bless({}, $name);
}

=item B<get>

Get a particular item from the table.

=cut
sub get {
    die("Method &get is abstract in class Devel::TypeCheck::Sym2type");
}

TRUE;

=back

=head1 AUTHOR

Gary Jackson, C<< <bargle at umiacs.umd.edu> >>

=head1 BUGS

This version is specific to Perl 5.8.1.  It may work with other
versions that have the same opcode list and structure, but this is
entirely untested.  It definitely will not work if those parameters
change.

Please report any bugs or feature requests to
C<bug-devel-typecheck at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-TypeCheck>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Gary Jackson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
