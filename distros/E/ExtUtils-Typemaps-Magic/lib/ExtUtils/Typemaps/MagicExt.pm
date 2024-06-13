package ExtUtils::Typemaps::MagicExt;
$ExtUtils::Typemaps::MagicExt::VERSION = '0.005';
use strict;
use warnings;

use parent 'ExtUtils::Typemaps';

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->add_inputmap(xstype => 'T_MAGICEXT', code => <<'END');
	{
	MAGIC* magic = SvROK($arg) && SvMAGICAL(SvRV($arg)) ? mg_findext(SvRV($arg), PERL_MAGIC_ext, &${type}_magic) : NULL;
	if (magic)
		$var = (${type})magic->mg_ptr;
	else
		Perl_croak(aTHX_ \"${ntype} object is lacking magic\");
	}
END

	$self->add_outputmap(xstype => 'T_MAGICEXT', code => <<'END');
	{
	MAGIC* magic = sv_magicext(newSVrv($arg, \"${ntype}\"), NULL, PERL_MAGIC_ext, &${type}_magic, (const char*)$var, 0);
	magic->mg_flags |= MGf_COPY|MGf_DUP;
	}
END

	return $self;
}

sub minimum_pxs {
	return '3.50';
}

1;

# ABSTRACT: Typemap for storing objects in magic

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Typemaps::MagicExt - Typemap for storing objects in magic

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use ExtUtils::Typemaps::MagicExt;
 # First, read my own type maps:
 my $private_map = ExtUtils::Typemaps->new(file => 'my.map');

 # Then, get the Magic set and merge it into my maps
 my $map = ExtUtils::Typemaps::MagicExt->new;
 $private_map->merge(typemap => $map);

 # Now, write the combined map to an output file
 $private_map->write(file => 'typemap');

=head1 DESCRIPTION

C<ExtUtils::Typemaps::MagicExt> is an C<ExtUtils::Typemaps> subclass that stores the object just like C<T_MAGIC> does, but additionally attaches a magic vtable (type C<MGVTBL>) with the name C<${type}_magic> (e.g. C<Foo__Bar_magic> for a value of type C<Foo::Bar>) to the value. This is mainly useful for adding C<free> (destruction) and C<dup> (thread cloning) callbacks. The details of how these work is explained in L<perlguts|perlguts>, but it might look something like this:

 static int object_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* params) {
     object_refcount_increment((struct Object*)magic->mg_ptr);
     return 0;
 }

 static int object_free(pTHX_ SV* sv, MAGIC* magic) {
     object_refcount_decrement((struct Object*)magic->mg_ptr);
     return 0;
 }

 static const MGVTBL My__Object_magic = { NULL, NULL, NULL, NULL, object_free, NULL, object_dup, NULL };

This is useful to create objects that handle thread cloning correctly and effectively. If the object may be destructed by another thread, it should be allocated with the C<PerlSharedMem_malloc> family of allocators.

=head1 DEPENDENCIES

This typemap requires L<ExtUtils::ParseXS|ExtUtils::ParseXS> C<3.50> or higher as a build dependency.

On perls older than C<5.14>, this will require F<ppport.h> to provide C<mg_findext>. E.g.

 #define NEED_mg_findext
 #include "ppport.h"

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
