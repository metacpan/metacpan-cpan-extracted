package JSON::Hyper::Link;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.011';

use strict qw( subs vars );

sub new
{
	my ($class, $self) = @_;
	$self = +{ href => $self } unless ref $self;
	bless $self => $class;
}

my @attr = qw/
	href
	rel
	targetSchema
	method
	enctype
	schema
	properties
/;

foreach my $attr (@attr)
{
	*$attr = sub {
		shift->{$attr};
	};
}

*target_schema = \&targetSchema;

1;

__END__

=head1 NAME

JSON::Hyper::Link - represents a link found in a JSON document

=head1 DESCRIPTION

This is a tiny object representng a hyperlink found in a JSON document.
You totally have my permission to treat it as a hashref if you want.
Encapsulation, ensmapulation!

=head2 Constructor

Generally speaking you don't want to construct these. They're constructed
by JSON::Hyper's C<find_links> method and I can't think of any conceivable
reason why you'd want to construct one yourself. Nevertheless...

=over

=item C<< new(\%attrs) >>

=item C<< new($uri) >>

Constructor takes a hashref of attributes, or a single URI as a string.

=back

=head2 Attributes

These attributes are hash keys for the constructor, and also exist as
methods that can be called on the object to retrieve the value.

=over

=item C<href>

The URL linked to.

=item C<rel>

The relationship between the URL has with the document that linked to it.

=item C<targetSchema>

A JSON schema (see L<JSON::Schema>) that the URL linked to supposedly
conforms to.

A method C<target_schema> is also available if you're alergic to camelCase,
but C<targetSchema> is the only attribute recognised by the constructor.

=begin trustme

=item C<target_schema>

=end trustme

=item C<method>

The HTTP method recommended for interacting with the URL. If undef, then
'GET' is usually a good bet.

=item C<enctype>

If POSTing data to this URL, the recommended Content-Type header.

=item C<schema>

=item C<properties>

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

Related modules: L<JSON::Hyper>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2010-2012 Toby Inkster.

This module is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=head2 a.k.a. "The MIT Licence"

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
