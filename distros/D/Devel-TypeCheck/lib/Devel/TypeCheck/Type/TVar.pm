package Devel::TypeCheck::Type::TVar;

use strict;
use Carp;

use Devel::TypeCheck::Type;
use Devel::TypeCheck::Util;

=head1 NAME

Devel::TypeCheck::Type::TVar - Methods to inherit for types that allow
type variables as subtypes.

=head1 SYNOPSIS

 use Devel::TypeCheck::Type::TVar;

 @ISA = (... Devel::TypeCheck::Type::TVar ...)

=head1 DESCRIPTION

This type overrides the unify method from Devel::TypeCheck::Type to
allow for having a type variable as a subtype.

Inherits from Devel::TypeCheck::Type.

=cut
our @ISA = qw(Devel::TypeCheck::Type);

# **** INSTANCE ****

sub unify {
    my ($this, $that, $env) = @_;

    $this = $env->find($this);
    $that = $env->find($that);

    if ($this->type == $that->type) {
	# If a subtype is VAR, then we need to go back to the main
	# unify()
	if ($this->subtype->type == Devel::TypeCheck::Type::VAR() ||
	    $that->subtype->type == Devel::TypeCheck::Type::VAR()) {
	    return $env->unify($this->subtype, $that->subtype);
	} else {
	    return $this->subtype->unify($that->subtype, $env);
	}
    } else {
	return undef;
    }
}

sub type {
    croak("Method &type not implemented for abstract class Devel::TypeCheck::Type::TVar");
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
