package HTML::FromArrayref;

use 5.006;
use strict;
use warnings;

use base qw( Exporter );
our @EXPORT = qw( HTML );
our @EXPORT_OK = qw( start_tag end_tag html_strict html_transitional html_frameset );
our %EXPORT_TAGS = (
	TAGS => [qw( start_tag end_tag )],
	DOCTYPES => [qw( html_strict html_transitional html_frameset )]
);

use HTML::Entities;

=head1 NAME

HTML::FromArrayref - Output HTML described by a Perl data structure

=head1 VERSION

Version 1.06

=cut

our $VERSION = '1.06';

=head1 SYNOPSIS

  use HTML::FromArrayref;
  print HTML [ html => [ head => [ title => 'My Web page' ] ], [ body => 'Hello' ] ];

=head1 EXPORT

This module exports an HTML() function that lets you easily print valid HTML without embedding it in your Perl code.

=head1 SUBROUTINES/METHODS

=head2 HTML(@)

Takes a list of strings and arrayrefs describing HTML content and returns the HTML string. The strings are encoded; each arrayref represents an HTML element, as follows:

  [ $tag_name, $attributes, @content ]

=head3 $tag_name

evaluates to a tag name such as 'html', 'head', 'title', 'body', 'table', 'tr', 'td', 'p', &c. If $tag_name is false then the whole element is replaced by its content.

If an arrayref's first element is another arrayref instead of an tag name, then the value of the first item of that array will be included in the HTML string but will not be encoded. This lets you include text in the HTML that has already been entity-encoded.

=head3 $attributes

is an optional hashref defining the element's attributes. If an attribute's value is undefined then the attribute will not appear in the generated HTML string. Attribute values will be encoded. If there isn't a hashref in the second spot in the element-definition list then the element won't have any attributes in the generated HTML.

=head3 @content

is another list of strings and arrayrefs, which will be used to generate the content of the element. If the content list is empty, then the element has no content and will be represented in the generated HTML string by adjacent start and end tags. The content of elements that are defined in the HTML 4.01 specification as "void" will be discarded, and only their start tag will be printed.

=cut

sub HTML (@) {
	join '', grep defined $_, map {
		ref $_ eq 'ARRAY' ? element( @$_ ) : encode_entities( $_ )
	} @_;
}

=head2 element()

Recursively renders HTML elements from arrayrefs

=cut

my %void; @void{ qw(
	area base br col command embed hr img input
	keygen link meta param source track wbr
) } = (1)x16;

sub element {
	my ( $tag_name, $attributes, @content ) = @_;

	# If an element's name is an array ref then it's
	# really text to print without encoding
	return $tag_name->[0] if ref $tag_name eq 'ARRAY';

	# If the second item in the list is not a hashref,
	# then the element has no attributes
	if ( defined $attributes and ref $attributes ne 'HASH' ) {
		unshift @content, $attributes;
		undef $attributes;
	}

	# If the first expression in the list is false, then skip
	# the element and return its content instead
	return HTML( @content ) if not $tag_name;

	# Return the element start tag with its formatted and
	# encoded attributes, and (optionally) content and
	# end tag
	join '', '<', $tag_name, attributes( %$attributes ), '>',
		! $void{ lc $tag_name } && ( HTML( @content ), "</$tag_name>" );
}

=head2 start_tag()

Takes a list with an element name and an optional hashref defining the element's attributes, and returns just the opening tag of the element. This and end_tag() are useful in those occasions when you really want to print out HTML piecewise procedurally, rather than building the whole page in memory.

=cut

sub start_tag {
	my ( $tag_name, $attributes ) = @_;

	join '', grep $_,
		'<', $tag_name, attributes( %$attributes ), '>';
}

=head2 end_tag()

Just takes an element name and returns the end tag for that element.

=cut

sub end_tag { "</$_[0]>" }

=head2 attributes()

Takes a hash of HTML element attributes and returns an encoded string for use in a tag

=cut

sub attributes {

	return unless my %attributes = @_;

	my @html;
	for ( keys %attributes ) {
		if ( defined $attributes{$_} ) {
			push @html, join '', $_, '="', encode_entities( $attributes{$_} ), '"';
		}
	}
	join ' ', '', @html;
}

=head2 DOCTYPEs

These make it easy to add a valid doctype declaration to your document

=cut

sub html_strict { << '' }
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
	"http://www.w3.org/TR/html4/strict.dtd">

sub html_transitional { << '' }
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
	"http://www.w3.org/TR/html4/loose.dtd">

sub html_frameset { << '' }
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN"
	"http://www.w3.org/TR/html4/frameset.dtd">

=head1 EXAMPLES

Note that I've formatted the output HTML for clarity - the html() function returns it all machine-readable and compact.

=head2 Simple content

Strings are just encoded and printed, so

  print HTML 'Hi there, this & that';

would print

  Hi there, this &amp; that

=head2 Literal content

If an element's name is an arrayref, its first item is printed without being encoded; this lets you include text that is already encoded by double-bracketing it:

  print HTML [ p => [[ '&copy; Angel Networks&trade;' ]] ];

would print

  <p>&copy; Angel Networks&trade;</p>

=head2 Using map to iterate, and optional elements

You can map any element over a list to iterate it, and by testing the value being mapped over can wrap some values in sub-elements:

  print HTML map [ p => [ $_ > 100 && 'b' => $_ ] ], 4, 450, 12, 44, 74, 102;

would print

  <p>4</p>
  <p><b>450</b></p>
  <p>12</p>
  <p>44</p>
  <p>74</p>
  <p><b>102</b></p>

=head2 Optional attributes

Similarly, by testing the value being mapped over in the attributes hash, you can set an attribute for only some values. Note that you have to explicitly return undef to skip the attribute since 0 is a valid value for an attribute.

  print HTML [ select => { name => 'State' },
    map
      [ option => { selected => $_ eq $c{state} || undef }, $_ ],
      @states
  ];

would print

  <select name="State">
    <option>Alabama</option>
    <option selected="1">Alaska</option>
    <option>Arkansas</option>
    ...
  </select>

assuming $c{state} equalled 'Alaska'.

=head2 Printing HTML tags one at a time

Sometimes you really don't want to build the whole page before printing it; you'd rather loop through some data and print an element at a time. The start_tag and end_tag functions will help you do this:

  print start_tag( [ td => { colspan => 3 } ] );
  print end_tag( 'td' );

would print

  <td colspan="3">
  </td>

=head1 SEE ALSO

L<The HTML 4.01 specification|http://www.w3.org/TR/html401/>

=head1 AUTHOR

Nic Wolff, <nic@angel.net>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/nicwolff/HTML-FromArrayref/issues>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::FromArrayref

You can also look for information at:

=over 4

=item * This module on GitHub

L<https://github.com/nicwolff/HTML-FromArrayref>

=item * GitHub request tracker (report bugs here)

L<https://github.com/nicwolff/HTML-FromArrayref/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-FromArrayref>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-FromArrayref/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Nic Wolff.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of HTML::FromArrayref
