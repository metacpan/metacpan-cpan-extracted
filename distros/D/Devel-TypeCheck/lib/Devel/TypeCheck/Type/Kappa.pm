package Devel::TypeCheck::Type::Kappa;

use strict;
use Carp;

use Devel::TypeCheck::Type;
use Devel::TypeCheck::Type::TSub;
use Devel::TypeCheck::Type::TVar;
use Devel::TypeCheck::Util;

=head1 NAME

Devel::TypeCheck::Type::Kappa - Type representing scalar values.

=head1 SYNOPSIS

 use Devel::TypeCheck::Type::Kappa;

=head1 DESCRIPTION

Kappa represents scalar values.  The underlying subtype can be a
variable, to represent a generic scalar, or an Upsilon or Rho type to
represent a "printable" type and a reference, respectively.

Inherits from Devel::TypeCheck::Type::TSub and Devel::TypeCheck::Type::TVar.

=cut
our @ISA = qw(Devel::TypeCheck::Type::TSub Devel::TypeCheck::Type::TVar);

# **** CLASS ****

our @SUBTYPES;
our @subtypes;

BEGIN {
    @SUBTYPES = (Devel::TypeCheck::Type::P(), Devel::TypeCheck::Type::Y(), Devel::TypeCheck::Type::VAR());

    for my $i (@SUBTYPES) {
	$subtypes[$i] = 1;
    }
}

sub hasSubtype {
    my ($this, $index) = @_;
    return ($subtypes[$index]);
}

sub type {
    return Devel::TypeCheck::Type::K();
}

sub deref {
    my ($this) = @_;
    return $this->subtype->deref;
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
