package Devel::TypeCheck::Type::TRef;

use strict;
use Carp;

use Devel::TypeCheck::Util;

=head1 NAME

Devel::TypeCheck::Type::TRef - generic reference type

=head1 SYNOPSIS

 use Devel::TypeCheck::Type::TRef;

=head1 DESCRIPTION

This defines the interface for reference types.  This no longer serves
much of a purpose, and should probably be removed.

=cut
# **** INSTANCE ****

sub deref {
    my ($this) = @_;
    return $this->subtype;
}

sub is {
    my ($this, $type) = @_;
    if ($this->type == $type) {
	return TRUE;
    } else {
	return FALSE;
    }
}

sub type {
    croak("Method &type is abstract in class Devel::TypeCheck::Type::Ref");
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
