package ExtUtils::Typemaps::Magic;
$ExtUtils::Typemaps::Magic::VERSION = '0.005';
use strict;
use warnings;

use parent 'ExtUtils::Typemaps';

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->add_inputmap(xstype => 'T_MAGIC', code => <<'END');
	{
	MAGIC* magic = SvROK($arg) && SvMAGICAL(SvRV($arg)) ? mg_findext(SvRV($arg), PERL_MAGIC_ext, NULL) : NULL;
	if (magic)
		$var = (${type})magic->mg_ptr;
	else
		Perl_croak(aTHX_ \"${ntype} object is lacking magic\");
	}
END

	$self->add_outputmap(xstype => 'T_MAGIC', code => '	sv_magic(newSVrv($arg, \"${ntype}\"), NULL, PERL_MAGIC_ext, (const char*)$var, 0);');

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

version 0.005

=head1 SYNOPSIS

 use ExtUtils::Typemaps::Magic;
 # First, read my own type maps:
 my $private_map = ExtUtils::Typemaps->new(file => 'my.map');

 # Then, get the Magic set and merge it into my maps
 my $map = ExtUtils::Typemaps::Magic->new;
 $private_map->merge(typemap => $map);

 # Now, write the combined map to an output file
 $private_map->write(file => 'typemap');

=head1 DESCRIPTION

C<ExtUtils::Typemaps::Magic> is an C<ExtUtils::Typemaps> subclass that is essentially a drop-in replacement for C<T_PTROBJ>, except that it hides the value of the pointer from pure-perl code by storing it in attached magic. In particular that means the pointer won't be serialized/deserialized (this is usually a thing because after deserialization the pointer is probably not valid). Note that like C<T_PTROBJ>, you probably need a C<DESTROY> method to destroy and free the buffer, and this is not thread cloning safe without further measures.

=head1 DEPENDENCIES

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
