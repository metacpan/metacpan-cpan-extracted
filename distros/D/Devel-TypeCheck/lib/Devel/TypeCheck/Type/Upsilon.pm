package Devel::TypeCheck::Type::Upsilon;

use strict;
use Carp;

use Devel::TypeCheck::Type;
use Devel::TypeCheck::Type::TSub;
use Devel::TypeCheck::Type::TVar;
use Devel::TypeCheck::Util;

=head1 NAME

Devel::TypeCheck::Type::Upsilon - Type representing printable values.

=head1 SYNOPSIS

 use Devel::TypeCheck::Type::Upsilon;

=head1 DESCRIPTION

Upsilon represents printable values.  A "printable value" is a string
or an integer.  This serves to represent scalar values where a human
readable type is desired, or where information about references are
lost (for instance, as a key in a hash).  Underlying subtypes can be
numbers (Nu), strings (PV), or type variables to represent ambiguity.

Inherits from Devel::TypeCheck::Type::TSub and Devel::TypeCheck::Type::TVar.

=cut
our @ISA = qw(Devel::TypeCheck::Type::TSub Devel::TypeCheck::Type::TVar);

# **** CLASS ****

our @SUBTYPES;
our @subtypes;

BEGIN {
    @SUBTYPES = (Devel::TypeCheck::Type::N(), Devel::TypeCheck::Type::PV(), Devel::TypeCheck::Type::VAR());

    for my $i (@SUBTYPES) {
	$subtypes[$i] = 1;
    }
}

sub hasSubtype {
    my ($this, $index) = @_;
    return ($subtypes[$index]);
}

sub type {
    return Devel::TypeCheck::Type::Y();
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
