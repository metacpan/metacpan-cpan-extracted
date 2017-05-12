package Devel::TypeCheck::Type::TSub;

use strict;
use Carp;

use Devel::TypeCheck::Util;

=head1 NAME

Devel::TypeCheck::Type::TSub - Interface for types with subtypes.

=head1 SYNOPSIS

 use Devel::TypeCheck::Type::TSub;

 @ISA(... Devel::TypeCheck::Type::TSub ...);

=head1 DESCRIPTION

=over 4

=cut
# **** INSTANCE ****

=item B<hasSubtype>

Abstract method forcing inheritors to override hasSubtype.

=cut
sub hasSubtype {
    croak("Method &hasSubtype is abstract in Devel::TypeCheck::Type::TSub");
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
