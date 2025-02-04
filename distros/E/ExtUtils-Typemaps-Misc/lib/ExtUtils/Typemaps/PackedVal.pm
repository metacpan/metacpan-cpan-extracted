package ExtUtils::Typemaps::PackedVal;
$ExtUtils::Typemaps::PackedVal::VERSION = '0.003';
use strict;
use warnings;

use parent 'ExtUtils::Typemaps';

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);

	$self->add_inputmap(xstype => 'T_PACKEDVAL', code => '$var = XS_unpack_$ntype($arg)');
	$self->add_outputmap(xstype => 'T_PACKEDVAL', code => '$arg = XS_pack_$ntype($var);');

	return $self;
}

1;

# ABSTRACT: Typemap for storing objects using external helper functions

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Typemaps::PackedVal - Typemap for storing objects using external helper functions

=head1 VERSION

version 0.003

=head1 SYNOPSIS

In typemap

 foobar_t    T_PACKEDVAL

In your XS:

 foobar_t XS_unpack_foobar_t(SV* sv);
 SV* XS_pack_foobar_t(foobar_t foobar);
 
 MODULE = Foo::Bar    PACKAGE = Foo::Bar
 
 foobar_t foobar(foobar_t input)

=head1 DESCRIPTION

C<ExtUtils::Typemaps::PackedVal> is a typemap bundle that stores one typemap: C<T_PACKEDVAL>.

For input parameters it's exactly the same as C<T_PACKED>, but for output parameters it does things slightly diferently: it returns the new C<SV*> instead of writing to an C<SV*> argument.

=head1 INCLUSION

To use this typemap template you need to include it into your local typemap. The easiest way to do that is to use the L<typemap> script in L<App::typemap>. E.g.

 typemap --merge ExtUtils::Typemaps::PackedVal

If you author using C<Dist::Zilla> you can use L<Dist::Zilla::Plugin::Typemap> instead.

Alternatively, you can include it at runtime by adding the following to your XS file:

 INCLUDE_COMMAND: $^X -MExtUtils::Typemaps::Cmd -e "print embeddable_typemap('PackedVal')"

That does require adding a build time dependency on this module.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
