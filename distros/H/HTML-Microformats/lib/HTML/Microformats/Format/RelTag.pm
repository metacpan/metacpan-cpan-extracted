=head1 NAME

HTML::Microformats::Format::RelTag - the rel-tag microformat

=head1 SYNOPSIS

 my @tags = HTML::Microformats::Format::RelTag->extract_all(
                   $doc->documentElement, $context);
 foreach my $tag (@tags)
 {
   print $tag->get_href . "\n";
 }

=head1 DESCRIPTION

HTML::Microformats::Format::RelTag inherits from HTML::Microformats::Format_Rel. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=head2 Additional Methods

=over 4

=item C<< $reltag->get_tag() >>

Returns the tag being linked to. Given the following link:

  http://example.com/foo/bar?baz=quux#xyzzy

the tag is "bar".

=item C<< $reltag->get_tagspace() >>

Returns the tagspace of the tag being linked to. Given the following link:

  http://example.com/foo/bar?baz=quux#xyzzy

the tagspace is "http://example.com/foo/".

=back

=cut

package HTML::Microformats::Format::RelTag;

use base qw(HTML::Microformats::Format_Rel);
use strict qw(subs vars); no warnings;
use 5.010;

use CGI::Util qw(unescape);

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::RelTag::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::RelTag::VERSION   = '0.105';
}

sub new
{
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	
	my $tag = $self->{'DATA'}->{'href'};
	$tag =~ s/\#.*$//;
	$tag =~ s/\?.*$//;
	$tag =~ s/\/$//;
	if ($tag =~ m{^(.*/)([^/]+)$})
	{
		$self->{'DATA'}->{'tagspace'} = $1;
		$self->{'DATA'}->{'tag'}      = unescape($2);
	}

	return $self;
}

sub format_signature
{
	my $t    = 'http://www.holygoat.co.uk/owl/redwood/0.1/tags/';
	my $awol = 'http://bblfish.net/work/atom-owl/2006-06-06/#';
	
	return {
		'rel'      => 'tag' ,
		'classes'  => [
				['tag',      '1#'] ,
				['tagspace', '1#'] ,
				['href',     '1#'] ,
				['label',    '1#'] ,
				['title',    '1#'] ,
			] ,
		'rdf:type' => ["${t}Tag","${awol}Category"] ,
		'rdf:property' => {
			'tag'      => { 'literal'  => ["${awol}term", "${t}name", "http://www.w3.org/2000/01/rdf-schema#label"] },
			'tagspace' => { 'resource' => ["${awol}scheme"] },
			'href'     => { 'resource' => ["http://xmlns.com/foaf/0.1/page"] },
			} ,
		}
}

sub profiles
{
	return qw(http://microformats.org/profile/rel-tag
		http://ufs.cc/x/rel-tag
		http://microformats.org/profile/specs
		http://ufs.cc/x/specs
		http://purl.org/uF/rel-tag/1.0/
		http://purl.org/uF/2008/03/);
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);
	
	$model->add_statement(RDF::Trine::Statement->new(
		RDF::Trine::Node::Resource->new($self->context->document_uri),
		RDF::Trine::Node::Resource->new('http://www.holygoat.co.uk/owl/redwood/0.1/tags/taggedWithTag'),
		$self->id(1),
		));

	return $self;
}

1;

=head1 MICROFORMAT

HTML::Microformats::Format::RelTag supports rel-tag as described at
L<http://microformats.org/wiki/rel-tag>.

The "title" attribute on the link, and the linked text are taken to be significant.

=head1 RDF OUTPUT

Data is returned using the Richard Newman's tag vocabulary
(L<http://www.holygoat.co.uk/owl/redwood/0.1/tags/>),
the Atom OWL vocabulary (L<http://bblfish.net/work/atom-owl/2006-06-06/#>)
and occasional other terms.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::Format_Rel>,
L<HTML::Microformats>,
L<HTML::Microformats::Format::hAtom>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut

