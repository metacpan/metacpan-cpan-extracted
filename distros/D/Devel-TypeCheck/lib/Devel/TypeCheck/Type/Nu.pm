package Devel::TypeCheck::Type::Nu;

use strict;
use Carp;

use Devel::TypeCheck::Type;
use Devel::TypeCheck::Type::TSub;
use Devel::TypeCheck::Util;

=head1 NAME

Devel::TypeCheck::Type::Nu - Type representing Number values.

=head1 SYNOPSIS

 use Devel::TypeCheck::Type::Nu;

=head1 DESCRIPTION

Nu represents number values.  The underlying subtype can be an IV
(integer) or DV (double float), or a variable to represent ambiguity.

Inherits from Devel::TypeCheck::Type::TSub and Devel::TypeCheck::Type::TVar.

=cut
our @ISA = qw(Devel::TypeCheck::Type::TSub Devel::TypeCheck::Type::TVar);

# **** CLASS ****

our @SUBTYPES;
our @subtypes;

BEGIN {
    @SUBTYPES = (Devel::TypeCheck::Type::IV(), Devel::TypeCheck::Type::DV(), Devel::TypeCheck::Type::VAR());

    for my $i (@SUBTYPES) {
	$subtypes[$i] = 1;
    }
}

sub hasSubtype {
    my ($this, $index) = @_;
    return ($subtypes[$index]);
}

sub type {
    return Devel::TypeCheck::Type::N();
}

sub pretty {
    my ($this, $env) = @_;
    return "NUMBER of " . $this->subtype->pretty($env);
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
