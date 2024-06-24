package ExtUtils::Typemaps::MagicBuf;
$ExtUtils::Typemaps::MagicBuf::VERSION = '0.007';
use strict;
use warnings;

use parent 'ExtUtils::Typemaps';

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->add_inputmap(xstype => 'T_MAGICBUF', code =>  <<'END');
	{
	%:ifdef mg_findext
	MAGIC* magic = SvROK($arg) && SvMAGICAL(SvRV($arg)) ? mg_findext(SvRV($arg), PERL_MAGIC_ext, NULL) : NULL;
	%:else
	MAGIC* magic = SvROK($arg) && SvMAGICAL(SvRV($arg)) ? mg_find(SvRV($arg), PERL_MAGIC_ext) : NULL;
	%:endif
	if (magic)
		$var = ($type)magic->mg_ptr;
	else
		Perl_croak(aTHX_ \"$ntype object is lacking magic\");
	}
END

	$self->add_outputmap(xstype => 'T_MAGICBUF', code => '	sv_magic(newSVrv($arg, "$ntype"), NULL, PERL_MAGIC_ext, (const char*)$var, sizeof(*$var));');

	return $self;
}

1;

# ABSTRACT: Typemap for storing objects in magic

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Typemaps::MagicBuf - Typemap for storing objects in magic

=head1 VERSION

version 0.007

=head1 SYNOPSIS

In your typemap

 My::Object	T_MAGICBUF

In your XS:

 typedef struct object_t* My__Object;

 MODULE = My::Object    PACKAGE = My::Object    PREFIX = object_

 My::Object object_new(int argument)

 int object_baz(My::Object self)

=head1 DESCRIPTION

C<ExtUtils::Typemaps::MagicBuf> is a typemap bundle that provides C<T_MAGICBUF>, a typemap for objects that uses a string reference to store your object in, except it is hidden away using magic. This is suitable for objects that can be safely shallow copied on thread cloning (i.e. they don't contain external references such as pointers or file descriptors). Unlike C<T_MAGIC> or C<T_PTROBJ> this does not need a C<DESTROY> method to free the buffer.

=head1 DEPENDENCIES

If your module supports perls older than C<5.14>, it is recommended to include F<ppport.h> to provide C<mg_findext>. E.g.

 #define NEED_mg_findext
 #include "ppport.h"

=head1 INCLUSION

To use this typemap template you need to include it into your local typemap. The easiest way to do that is to use the L<typemap> script in L<App::typemap>. E.g.

 typemap --merge ExtUtils::Typemaps::MagicBuf

If you author using C<Dist::Zilla> you can use L<Dist::Zilla::Plugin::Typemap> instead.

Alternatively, you can include it at runtime by adding the following to your XS file:

 INCLUDE_COMMAND: $^X -MExtUtils::Typemaps::Cmd -e "print embeddable_typemap('MagicBuf')"

That does require adding a build time dependency on this module.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
