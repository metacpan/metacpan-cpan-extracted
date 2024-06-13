package ExtUtils::Typemaps::MagicBuf;
$ExtUtils::Typemaps::MagicBuf::VERSION = '0.005';
use strict;
use warnings;

use parent 'ExtUtils::Typemaps';

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->add_inputmap(xstype => 'T_MAGICBUF', code =>  <<'END');
	{
	MAGIC* magic = SvROK($arg) && SvMAGICAL(SvRV($arg)) ? mg_findext(SvRV($arg), PERL_MAGIC_ext, NULL) : NULL;
	if (magic)
		$var = (${type})magic->mg_ptr;
	else
		Perl_croak(aTHX_ \"${ntype} object is lacking magic\");
	}
END

	$self->add_outputmap(xstype => 'T_MAGICBUF', code => '	sv_magic(newSVrv($arg, \"${ntype}\"), NULL, PERL_MAGIC_ext, (const char*)$var, sizeof(*$var));');

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

version 0.005

=head1 SYNOPSIS

 use ExtUtils::Typemaps::MagicBuf;
 # First, read my own type maps:
 my $private_map = ExtUtils::Typemaps->new(file => 'my.map');

 # Then, get the Magic set and merge it into my maps
 my $map = ExtUtils::Typemaps::MagicBuf->new;
 $private_map->merge(typemap => $map);

 # Now, write the combined map to an output file
 $private_map->write(file => 'typemap');

=head1 DESCRIPTION

C<ExtUtils::Typemaps::MagicBuf> is an C<ExtUtils::Typemaps> subclass that is the equivalent of using a string reference to store your object in, except it is hidden away using magic. This is suitable for objects that can be safely shallow copied on thread cloning (i.e. they don't contain external references such as pointers or file descriptors). Unlike C<T_MAGIC> or C<T_PTROBJ> this does not need a C<DESTROY> method to free the buffer.

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
