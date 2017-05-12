package HTML::HTML5::ToText::Trait::ShowLinks;

use 5.010;
use common::sense;
use utf8;

BEGIN {
	$HTML::HTML5::ToText::Trait::ShowLinks::AUTHORITY = 'cpan:TOBYINK';
	$HTML::HTML5::ToText::Trait::ShowLinks::VERSION   = '0.004';
}

use Moose::Role;

around [qw/A AREA/] => sub {
	my ($orig, $self, @args) = @_;
	my $return = $self->$orig(@args);
	my $elem = $args[0];
	return $return unless $elem->hasAttribute('href');
	sprintf("%s <%s>", $return, $elem->getAttribute('href'));
};

around LINK => sub {
	my ($orig, $self, $elem, %args) = @_;
	
	my $return = sprintf('<%s>', $elem->getAttribute('href'));
	
	$return = sprintf('"%s" %s', $elem->getAttribute('title'), $return)
		if $elem->hasAttribute('title');

	$return = sprintf('%s (%s)', $return, $elem->getAttribute('rel'))
		if $elem->hasAttribute('rel');

	return "LINK: $return\n";
};

1;

=head1 NAME

HTML::HTML5::ToText::Trait::ShowLinks - shows links

=head1 DESCRIPTION

Shows the href of C<< <a> >> elements; shows the href, title and rel of
C<< <link> >> elements.

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
