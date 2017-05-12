package FreeMind::Document;

use 5.010001;
use strict;
use warnings;

BEGIN {
	$FreeMind::Document::AUTHORITY = 'cpan:TOBYINK';
	$FreeMind::Document::VERSION   = '0.002';
}

use XML::LibXML::Augment
	-type  => 'Document',
	-names => ['map'],
;

require FreeMind::Map;
require FreeMind::Node;
require FreeMind::Icon;
require FreeMind::Edge;
require FreeMind::Font;
require FreeMind::Cloud;
require FreeMind::ArrowLink;
require FreeMind::Text;

use Carp;
use Types::Standard;

sub _has
{
	my $pkg = shift;
	while (@_)
	{
		my $name = shift;
		my $opts; $opts = shift if ref $_[0];
		next if $pkg->can($name);
		
		my $type     = $opts->{isa} || Types::Standard::Str;
		my $required = $opts->{required};
		
		my $sub = sub {
			my $node = shift;
			return $node->getAttribute($name) unless @_;
			
			my $v = $_[0];
			if (defined $v)
			{
				$type->assert_valid($v);
				$v = $v ? "true" : "false" if $type->name eq 'Bool';
				$node->setAttribute($name, $v);
			}
			else
			{
				croak "cannot set required attribute '$name' to undef" if $required;
				$node->removeAttribute($name);
			}
		};
		{ no strict "refs"; *{$pkg."::".lc $name} = $sub }
	}
}

sub load
{
	shift;
	"XML::LibXML::Augment"->rebless(
		"XML::LibXML"->load_xml(@_),
	);
}

sub root
{
	shift->findnodes('/map/node')->[0];
}

sub toHash
{
	shift->root->toHash;
}

sub toText
{
	shift->root->toText(@_);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

FreeMind::Document - representation of a FreeMind-style mind map document

=head1 SYNOPSIS

 my $document = "FreeMind::Document"->load(location => "todo.mm");
 
 my ($node) = $document->findnodes(q{//node[@ID="foo"]});
 
 print $node->toText, "\n";

=head1 DESCRIPTION

This is a subclass of L<XML::LibXML::Document> providing the following
additional methods:

=over

=item C<< load($type, $source) >>

Constructor. If C<< $type >> is C<< "IO" >> then C<< $source >> should be a
filehandle. If C<< $type >> is C<< "location" >> then C<< $source >> should
be a file name or URL. If If C<< $type >> is C<< "string" >> then
C<< $source >> should be a scalar string containing XML.

If the XML being loaded is a FreeMind mind map document, returns an instance
of FreeMind::Document. Otherwise returns an instance of XML::LibXML::Document.

=item C<< root >>

Returns the centre-most node of the mind map as a L<FreeMind::Node>.

=item C<< toHash >>

C<< $document->toHash >> is a shortcut for C<< $document->root->toHash >>.

=item C<< toText($indent, $width) >>

C<< $document->toText >> is a shortcut for C<< $document->root->toText >>.

=back

As this is an XML::LibXML::Document, you have all the standard methods for
traversing the document such as C<findnodes> and C<getElementsByTagName>,
but the elements returned by these methods will be L<FreeMind::Map>,
L<FreeMind::Node>, etc objects rather than L<XML::LibXML::Element> objects.

The XML elements provide accessors for XML attributes. For example, given
this XML element:

   <node
      CREATED="1365159476220"
      ID="ID_326312292"
      MODIFIED="1365441636185"
      POSITION="right"
      TEXT="documentation" />

You can call C<< $element->created >> to get the element's creation date
as an integer. Call it with an argument to write to the attribute:

   $element->created($some_time);

To remove the attribute, pass an explicit C<undef> as an argument. These
attribute accessors perform a limited amount of validation. The standard
XML::LibXML::Element C<getAttribute>, C<setAttribute> and C<removeAttribute>,
but these will perform no validation.

(Incidentally, FreeMind dates are milliseconds since the Unix epoch. The
setters will happily coerce from L<DateTime> objects though.)

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=FreeMind-Document>.

=head1 SEE ALSO

L<http://freemind.sourceforge.net/wiki/index.php/Main_Page>.

L<FreeMind::Map>, L<FreeMind::Node>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

