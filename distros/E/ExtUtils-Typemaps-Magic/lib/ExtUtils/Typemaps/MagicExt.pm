package ExtUtils::Typemaps::MagicExt;
$ExtUtils::Typemaps::MagicExt::VERSION = '0.009';
use strict;
use warnings;

use parent 'ExtUtils::Typemaps';

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->add_inputmap(xstype => 'T_MAGICEXT', code => <<'END');
	{
	SV* arg = $arg;
	MAGIC* magic = SvROK(arg) && SvMAGICAL(SvRV(arg)) ? mg_findext(SvRV(arg), PERL_MAGIC_ext, &${type}_magic) : NULL;
	if (magic)
		$var = ($type)magic->mg_ptr;
	else
		Perl_croak(aTHX_ \"%s object is lacking magic\", \"$ntype\");
	}
END
	$self->add_inputmap(xstype => 'T_MAGICEXT_BASE', code => <<'END');
	{
	SV* arg = $arg;
	MAGIC* magic = SvROK(arg) && SvMAGICAL(SvRV(arg)) ? mg_find(SvRV(arg), PERL_MAGIC_ext) : NULL;
	if (magic && magic->mg_virtual)
		$var = ($type)magic->mg_ptr;
	else
		Perl_croak(aTHX_ \"%s object is lacking magic\", \"$ntype\");
	}
END


	$self->add_outputmap(xstype => 'T_MAGICEXT', code => <<'END');
	{
	MAGIC* magic = sv_magicext(newSVrv($arg, "$ntype"), NULL, PERL_MAGIC_ext, &${type}_magic, (const char*)$var, 0);
	magic->mg_flags |= MGf_COPY|MGf_DUP;
	}
END

	return $self;
}

sub minimum_pxs {
	return '3.50';
}

1;

# ABSTRACT: Typemap for storing objects in magic pointer

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Typemaps::MagicExt - Typemap for storing objects in magic pointer

=head1 VERSION

version 0.009

=head1 SYNOPSIS

In your typemap

 My::Object	T_MAGICEXT

In your XS:

 static const MGVTBL My__Object_magic = {
     .svt_dup  = object_dup,
     .svt_free = object_free
 };

 typedef struct object_t* My__Object;

 MODULE = My::Object    PACKAGE = My::Object    PREFIX = object_

 My::Object object_new(int argument)

 int object_baz(My::Object self)

=head1 DESCRIPTION

C<ExtUtils::Typemaps::MagicExt> is a typemap bundle that provides C<T_MAGICEXT>, a typemap that stores the object just like C<T_MAGIC> does, but additionally attaches a magic vtable (type C<MGVTBL>) with the name C<${type}_magic> (e.g. C<My__Object_magic> for a value of type C<My::Object>) to the value. This is mainly useful for adding C<free> (destruction) and C<dup> (thread cloning) callbacks. The details of how these work is explained in L<perlguts|perlguts>, but it might look something like this:

 static int object_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* params) {
     struct Object* object = (struct Object*)magic->mg_ptr;
     object_refcount_increment(object);
     return 0;
 }

 static int object_free(pTHX_ SV* sv, MAGIC* magic) {
     struct Object* object = (struct Object*)magic->mg_ptr;
     object_refcount_decrement(object);
     return 0;
 }

This is useful to create objects that handle thread cloning correctly and effectively. If the object may be destructed by another thread, it should be allocated with the C<PerlSharedMem_malloc> family of allocators.

=head1 DEPENDENCIES

This typemap requires L<ExtUtils::ParseXS|ExtUtils::ParseXS> C<3.50> or higher as a build dependency.

On perls older than C<5.14>, this will require F<ppport.h> to provide C<mg_findext>. E.g.

 #define NEED_mg_findext
 #include "ppport.h"

=head1 INCLUSION

To use this typemap template you need to include it into your local typemap. The easiest way to do that is to use the L<typemap> script in L<App::typemap>. E.g.

 typemap --merge ExtUtils::Typemaps::MagicExt

If you author using C<Dist::Zilla> you can use L<Dist::Zilla::Plugin::Typemap> instead.

Alternatively, you can include it at runtime by adding the following to your XS file:

 INCLUDE_COMMAND: $^X -MExtUtils::Typemaps::Cmd -e "print embeddable_typemap('MagicExt')"

That does require adding a build time dependency on this module.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
