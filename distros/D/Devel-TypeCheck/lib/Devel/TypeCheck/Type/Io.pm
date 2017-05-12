package Devel::TypeCheck::Type::Io;

use strict;
use Carp;

use Devel::TypeCheck::Type;
use Devel::TypeCheck::Util;
use Devel::TypeCheck::Type::TTerm;

=head1 NAME

Devel::TypeCheck::Type::Io - Terminal type representing an IO handle.

=head1 SYNOPSIS

 use Devel::TypeCheck::Type::Io;

=head1 DESCRIPTION

Inherits from Devel::TypeCheck::Type::TTerm.

=cut
our @ISA = qw(Devel::TypeCheck::Type::TTerm);

# **** INSTANCE ****

sub type {
    return Devel::TypeCheck::Type::IO();
}

sub pretty {
    return "IO HANDLE";
}

TRUE;

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
