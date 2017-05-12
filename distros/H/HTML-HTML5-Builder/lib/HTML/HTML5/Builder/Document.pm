package HTML::HTML5::Builder::Document;

use HTML::HTML5::Writer 0.104 qw();
use XML::LibXML 1.60 qw();

use 5.008;
use base qw[XML::LibXML::Document];
use common::sense;
use overload '""' => \&toStringHTML;
use utf8;

BEGIN {
	$HTML::HTML5::Builder::Document::AUTHORITY = 'cpan:TOBYINK';
}
BEGIN {
	$HTML::HTML5::Builder::Document::VERSION   = '0.004';
}

sub new
{
	my ($class, @x) = @_;
	bless $class->SUPER::new(@x), $class;
}

sub toStringHTML
{
	my ($self, @x) = @_;
	return HTML::HTML5::Writer->new(@x)->document($self);
}

*serialize_html = \&toStringHTML;

1;

__END__

=head1 NAME

HTML::HTML5::Builder::Document - pretty trivial subclass of XML::LibXML::Document

=head1 DESCRIPTION

C<< HTML::HTML5::Builder::html() >> returns an C<HTML::HTML5::Builder::Document>
object. This inherits from C<XML::LibXML::Document>, but overloads stringification
using C<HTML::HTML5::Writer>.

A non-exhaustive list of interesting methods provided by C<HTML::HTML5::Builder::Document>
objects:

=over

=item C<toString> - outputs XML

=item C<toStringHTML> - outputs HTML

=item C<documentElement> - returns the root element as an C<XML::LibXML::Element>

=item C<findnodes> - search using XPath

=back

=head1 SEE ALSO

L<HTML::HTML5::Builder>,
L<XML::LibXML::Document>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

