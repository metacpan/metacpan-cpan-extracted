package HTML::HTML5::ToText::Trait::ShowImages;

use 5.010;
use common::sense;
use utf8;

BEGIN {
	$HTML::HTML5::ToText::Trait::ShowImages::AUTHORITY = 'cpan:TOBYINK';
	$HTML::HTML5::ToText::Trait::ShowImages::VERSION   = '0.004';
}

use Moose::Role;

around IMG => sub {
	my ($orig, $self, $elem, @args) = @_;
	
	if ($elem->hasAttribute('alt')
	and not length $elem->getAttribute('alt'))
	{
		return '';
	}

	if ($elem->hasAttribute('alt'))
	{
		return sprintf('[IMG: %s]', $elem->getAttribute('alt'));
	}

	return '[IMG]';
};

1;

=head1 NAME

HTML::HTML5::ToText::Trait::ShowImages - indicate where images are

=head1 DESCRIPTION

Shows C<< [IMG] >> for images with no alt; C<< [IMG: blah] >> for images
with an alt attribute; and no text at all for images with a zero-length alt
attribute.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=HTML-HTML5-ToText>.

=head1 SEE ALSO

L<HTML::HTML5::ToText>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
