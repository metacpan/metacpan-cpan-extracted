package Image::Leptonica;
# ABSTRACT: bindings to the Leptonica image processing library
$Image::Leptonica::VERSION = '0.04';
use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use Path::Class;
use Alien::Leptonica;
use Inline;
use ExtUtils::Depends;

our $leptonica_h = file(__FILE__)->dir
	->subdir('Leptonica')
	->file('leptonica.h')
	->slurp();

Inline->bind( C => $leptonica_h =>
	NAME => 'Image::Leptonica' =>
	VERSION => $Image::Leptonica::VERSION =>
	%{ Image::Leptonica::Inline('C') },
	ENABLE => AUTOWRAP =>
	BOOT => <<'END_BOOT_C'
		HV *stash = gv_stashpvn ("Image::Leptonica::FileFormat", strlen("Image::Leptonica::FileFormat"), TRUE);
		newCONSTSUB(stash, "IFF_PNM", newSViv (IFF_PNM));
		newCONSTSUB(stash, "IFF_PNG", newSViv (IFF_PNG));
END_BOOT_C
	);

sub Alien {
	our $alien = Alien::Leptonica->new;
	Alien::Leptonica::Inline(@_);
}


sub Inline {
	return unless $_[-1] eq 'C';
	our $info = ExtUtils::Depends::load('Image::Leptonica');
	+{
		%{ Image::Leptonica::Alien(@_) },
		TYPEMAPS  => $info->{typemaps},
	};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica - bindings to the Leptonica image processing library

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  use Image::Leptonica;

  # TODO

=head1 DESCRIPTION

This module binds to all the functions in the Leptonica image processing
library. It provides a very raw interface to the C functions.

=head1 Inline support

This module supports L<Inline's with functionality|Inline/"Playing 'with' Others">.

=head1 SEE ALSO

L<Leptonica|http://www.leptonica.com/>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
