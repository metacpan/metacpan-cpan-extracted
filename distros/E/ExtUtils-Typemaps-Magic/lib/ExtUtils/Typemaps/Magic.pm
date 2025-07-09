package ExtUtils::Typemaps::Magic;
$ExtUtils::Typemaps::Magic::VERSION = '0.009';
use strict;
use warnings;

use parent 'ExtUtils::Typemaps';

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->add_inputmap(xstype => 'T_MAGIC', code => <<'END');
	{
	SV* arg = $arg;
	MAGIC* magic = SvROK(arg) && SvRMAGICAL(SvRV(arg)) ? mg_findext(SvRV(arg), PERL_MAGIC_ext, NULL) : NULL;
	if (magic)
		$var = ($type)magic->mg_ptr;
	else
		Perl_croak(aTHX_ \"%s object is lacking magic\", \"$ntype\");
	}
END

	$self->add_outputmap(xstype => 'T_MAGIC', code => '	sv_magicext(newSVrv($arg, "$ntype"), NULL, PERL_MAGIC_ext, NULL, (const char*)$var, 0);');

	return $self;
}

1;

# ABSTRACT: Typemap for storing objects in magic

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Typemaps::Magic - Typemap for storing objects in magic

=head1 VERSION

version 0.009

=head1 SYNOPSIS

In your typemap

 My::Object	T_MAGIC

In your XS:

 typedef struct object_t* My__Object;

 MODULE = My::Object    PACKAGE = My::Object    PREFIX = object_

 My::Object object_new(int argument)

 int object_baz(My::Object self)

=head1 DESCRIPTION

C<ExtUtils::Typemaps::Magic> is a typemap bundle that provides C<T_MAGIC>, a drop-in replacement for C<T_PTROBJ> except that it hides the value of the pointer from pure-perl code by storing it in attached magic. In particular that means the pointer won't be serialized/deserialized (this is usually a good thing because after deserialization the pointer is probably not valid). Note that like C<T_PTROBJ>, you probably need a C<DESTROY> method to destroy and free the buffer, and this is not thread cloning safe without further measures.

=head1 DEPENDENCIES

On perls older than C<5.14>, this will require F<ppport.h> to provide C<mg_findext>. E.g.

 #define NEED_mg_findext
 #include "ppport.h"

=head1 INCLUSION

To use this typemap template you need to include it into your local typemap. The easiest way to do that is to use the L<typemap> script in L<App::typemap>. E.g.

 typemap --merge ExtUtils::Typemaps::Magic

If you author using C<Dist::Zilla> you can use L<Dist::Zilla::Plugin::Typemap> instead.

Alternatively, you can include it at runtime by adding the following to your XS file:

 INCLUDE_COMMAND: $^X -MExtUtils::Typemaps::Cmd -e "print embeddable_typemap('Magic')"

That does require adding a build time dependency on this module.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
