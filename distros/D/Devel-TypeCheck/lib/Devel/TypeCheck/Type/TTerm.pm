package Devel::TypeCheck::Type::TTerm;

use strict;
use Carp;

=head1 NAME

Devel::TypeCheck::Type::TTerm - Generic terminal types.

=head1 SYNOPSIS

 use Devel::TypeCheck::Type::TTerm;

 @ISA = (... Devel::TypeCheck::Type::TTerm ...);

=head1 DESCRIPTION

This abstract type overrides methods from Type to support terminal
types.

Inherits from Devel::TypeCheck::Type::Type.

=cut
our @ISA = qw(Devel::TypeCheck::Type);

use Devel::TypeCheck::Type qw(n2s);
use Devel::TypeCheck::Util;

# **** INSTANCE ****

sub new {
    my ($name) = @_;

    my $this = {};

    bless($this, $name);

    return $this;
}


sub unify {
    my ($this, $that, $env) = @_;

    $this = $env->find($this);
    $that = $env->find($that);

    if ($this->type == $that->type) {
	return $this->type;
    } else {
	return undef;
    }
}

sub occurs {
    my ($this, $that, $env) = @_;
    
    return FALSE;
}

sub type {
    croak("Method &type not implemented for abstract class Devel::TypeCheck::Type::TVar");
}

sub subtype {
    my ($this) = @_;
    confess("Method &subtype is abstract in class " . ref($this));
}

sub str {
    my ($this, $env) = @_;
    return ("<" . Devel::TypeCheck::Type::n2s($this->type) . ">");
}

sub deref {
    return undef;
}

sub is {
    my ($this, $type) = @_;
    if ($this->type == $type) {
	return TRUE;
    } else {
	return FALSE;
    }
}

sub complete {
    return TRUE;
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
