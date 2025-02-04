package ExtUtils::Typemaps::Misc;
$ExtUtils::Typemaps::Misc::VERSION = '0.003';
use strict;
use warnings;

use parent 'ExtUtils::Typemaps';

use ExtUtils::Typemaps::IntObj;
use ExtUtils::Typemaps::OpaqueObj;
use ExtUtils::Typemaps::Slurp;
use ExtUtils::Typemaps::PackedVal;

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);

	$self->merge(typemap => ExtUtils::Typemaps::IntObj->new);
	$self->merge(typemap => ExtUtils::Typemaps::OpaqueObj->new);
	$self->merge(typemap => ExtUtils::Typemaps::Slurp->new);
	$self->merge(typemap => ExtUtils::Typemaps::PackedVal->new);

	return $self;
}

1;

# ABSTRACT: A collection of miscelaneous typemap templates

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Typemaps::Misc - A collection of miscelaneous typemap templates

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This package is an aggregate typemap bundle of all of the bundles in this distribution:

=head2 OpaqueObj

L<ExtUtils::Typemaps::OpaqueObj> is a typemap bundle that contains C<T_OPAQUEOBJ>, a typemap for objects that are self contained and therefore can safely be copied for serialization and thread cloning.

=head2 IntObj

L<ExtUtils::Typemaps::IntObj> is a typemap bundle that contains C<T_INTOBJ> and C<INTREF>. This allows you to wrap an integer-like datatype (such as a handle) into a Perl object.

=head2 Slurp

L<ExtUtils::Typemaps::Slurp> is a typemap bundle that contains C<T_SLURP_VAL>, C<T_SLURP_VAR> and C<T_SLURP_AV>. These help when slurping all remaining arguments into a single value.

=head2 PackedVal

L<ExtUtils::Typemaps::PackedVal> is a typemap bundle that contains C<T_PACKEDVAL>. It's very similar to C<T_PACKED>, except the output typemap returns the new SV (instead of taking it as an argument).

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
