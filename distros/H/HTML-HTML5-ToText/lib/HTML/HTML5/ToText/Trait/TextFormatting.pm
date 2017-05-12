package HTML::HTML5::ToText::Trait::TextFormatting;

use 5.010;
use common::sense;
use utf8;

BEGIN {
	$HTML::HTML5::ToText::Trait::TextFormatting::AUTHORITY = 'cpan:TOBYINK';
	$HTML::HTML5::ToText::Trait::TextFormatting::VERSION   = '0.004';
}

use Moose::Role;

around [qw/B STRONG/] => sub {
	my ($orig, $self, @args) = @_;
	my $return = $self->$orig(@args);
	return "*${return}*";
};

around [qw/I EM/] => sub {
	my ($orig, $self, @args) = @_;
	my $return = $self->$orig(@args);
	$return =~ s/ /_/g;
	return "_${return}_";
};

around [qw/BIG/] => sub {
	my ($orig, $self, @args) = @_;
	my $return = $self->$orig(@args);
	uc $return;
};

1;

=head1 NAME

HTML::HTML5::ToText::Trait::TextFormatting - poor man's text formatting

=head1 DESCRIPTION

Adds formatting for *bold*, _italics_ and BIG TEXT.

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

