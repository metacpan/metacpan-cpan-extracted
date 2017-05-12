=head1 NAME

HTML::Microformats::Format::OpenURL_COinS - the OpenURL COinS poshformat

=head1 SYNOPSIS

 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::OpenURL_COinS;
 use Data::Dumper;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @objects = HTML::Microformats::Format::OpenURL_COinS->extract_all(
                   $dom->documentElement, $context);
 my $object = $objects[0];
 print Dumper($object->data);

=head1 DESCRIPTION

HTML::Microformats::Format::OpenURL_COinS inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::Format::OpenURL_COinS;

use base qw(HTML::Microformats::Format);
use strict qw(subs vars); no warnings;
use 5.010;

use CGI;
use CGI::Util qw(escape);
use HTML::Microformats::Utilities qw(stringify xml_stringify);

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::OpenURL_COinS::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::OpenURL_COinS::VERSION   = '0.105';
}

sub new
{
	my ($class, $element, $context) = @_;
	my $cache = $context->cache;
	
	return $cache->get($context, $element, $class)
		if defined $cache && $cache->get($context, $element, $class);
	
	my $self = {
		'element'    => $element ,
		'context'    => $context ,
		'cache'      => $cache ,
		};	
	bless $self, $class;

	my $success = $self->_parse_coins;
	return unless $success;

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub _parse_coins
{
	my $self = shift;
	my $e    = $self->{'element'};
	
	my $openurl;
	if ($e->localname =~ /^(q|blockquote)$/i && $e->hasAttribute('cite'))
	{
		($openurl = $e->getAttribute('cite')) =~ s/^([^\?]*\?)//;
	}
	elsif ($e->localname =~ /^(a|area|link)$/i && $e->hasAttribute('href'))
	{
		($openurl = $e->getAttribute('href')) =~ s/^([^\?]*\?)//;
	}
	else
	{
		$openurl = $e->getAttribute('title');
	}

	my $cgi = new CGI($openurl);
	return 0 unless ($cgi->param('ctx_ver') eq 'Z39.88-2004');
	
	my $id = '';
	foreach my $param (sort $cgi->param)
	{
		foreach my $value (sort $cgi->param($param))
		{
			push @{$self->{'DATA'}->{'openurl_data'}->{$param}}, $value;
			$id .= sprintf('&%s=%s', escape($param), escape($value));
		}
	}
	($self->{'DATA'}->{'openurl'} = $id) =~ s|^&||;
	($self->{'id.co'} = $id) =~ s|^&|http://ontologi.es/openurl?|;
	
	if ($e->localname =~ /^(q|blockquote)$/i)
	{
		$self->{'DATA'}->{'quote'} = xml_stringify($e);
	}
	elsif ($e->localname =~ /^(a|cite)$/i)
	{
		$self->{'DATA'}->{'label'} = stringify($e);
	}
	
	return 1;
}

sub format_signature
{
	my $ov   = 'http://open.vocab.org/terms/';
	my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
	my $dc   = 'http://purl.org/dc/terms/';
	my $ou   = 'http://www.openurl.info/registry/fmt/xml/rss10/ctx#';

	return {
		'root' => 'Z3988',
		'rel'  => 'Z3988',
		'classes' => [
			['label',        '?#'],
			['quote',        '?#'],
			['openurl',      '1#'],
			['openurl_data', '1#'],
		],
		'options' => {},
		'rdf:type' => [] ,
		'rdf:property' => {
			'label'    => { literal => ["${rdfs}label"] },
			'quote'    => { literal => ["${ov}quote"] },
			'openurl'  => { literal => ["${dc}identifier"] , literal_datatype => 'string' },
		},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);

	my $ov   = 'http://open.vocab.org/terms/';
	my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
	my $dc   = 'http://purl.org/dc/terms/';
	my $ou   = 'http://www.openurl.info/registry/fmt/xml/rss10/ctx#';
	my $bibo = 'http://purl.org/ontology/bibo/';
	
	$model->add_statement(RDF::Trine::Statement->new(
		RDF::Trine::Node::Resource->new($self->context->document_uri),
		RDF::Trine::Node::Resource->new("${dc}references"),
		$self->id(1),
		));

	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1),
		RDF::Trine::Node::Resource->new("http://ontologi.es/openurl#context"),
		$self->id(1, 'co'),
		));

	# OpenURL's structure is very flat and difficult to
	# properly map to BIBO. Here is a partial mapping.
	my %bibokey = (
		'rft.btitle' => "${dc}title" ,
		'rft.coden'  => "${bibo}coden" ,
		'rft.date'   => "${dc}date" ,
		'rft.eissn'  => "${bibo}eissn" ,
		'rft.isbn'   => "${bibo}isbn" ,
		'rft.issn'   => "${bibo}issn" ,
		'rft.sici'   => "${bibo}sici" ,
		);
	my $au = 0;

	foreach my $key (keys %{$self->{'DATA'}->{'openurl_data'}})
	{
		foreach my $val (@{$self->{'DATA'}->{'openurl_data'}->{$key}})
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$self->id(1, 'co'),
				RDF::Trine::Node::Resource->new($ou . $key),
				$self->_make_literal($val),
				));
			if (defined $bibokey{$key})
			{
				$model->add_statement(RDF::Trine::Statement->new(
					$self->id(1),
					RDF::Trine::Node::Resource->new($bibokey{$key}),
					$self->_make_literal($val),
					));
			}
			if ($key eq 'rft.au')
			{
				$au++;
				$model->add_statement(RDF::Trine::Statement->new(
					$self->id(1),
					RDF::Trine::Node::Resource->new("${dc}contributor"),
					$self->id(1, 'au.'.$au),
					));
				$model->add_statement(RDF::Trine::Statement->new(
					$self->id(1, 'au.'.$au),
					RDF::Trine::Node::Resource->new("http://xmlns.com/foaf/0.1/name"),
					$self->_make_literal($val),
					));
			}
		}
	}
}

sub profiles
{
	return qw(http://ocoins.info/);
}

1;

=head1 MICROFORMAT

OpenURL COinS is not technically a microformat. It was developed outside the
microformats community and does not use many of the patterns developed by
that community. Nevertheless it's an interesting format, and perhaps a useful
one.

HTML::Microformats::Format::OpenURL_COinS supports COinS as described at
L<http://ocoins.info/>, with the following addition:

=over 4

=item * Support for additional elements and attributes

OpenURL COinS is only specified to work on E<lt>spanE<gt> elements.
This module allows its use on arbitrary HTML elements. When used with
E<lt>qE<gt> or E<lt>blockquoteE<gt> the 'cite' attribute is consulted
in preference to 'title'; when used with E<lt>linkE<gt>, E<lt>aE<gt>
or E<lt>areaE<gt>, 'href' is used in preference to 'title'.

When either of the 'cite' or 'href' attributes is used, any leading string
ending with a question mark is removed from the attribute value prior
to OpenURL processing. This allows for the attibute values to be published
as proper links.

When E<lt>qE<gt> or E<lt>blockquoteE<gt> is used, the quote
is taken to be sourced from the entity described by the context object.

=back

=head1 RDF OUTPUT

Like how HTML::Microformats::Format::hCard differentiates between the business card
and the entity represented by the card, this module differentiates between the
OpenURL context object and the book, journal entry or other publication
represented by it. The former is essentially a set of search parameters which
can be used to find the latter.

The RSS Context module (L<http://www.openurl.info/registry/fmt/xml/rss10/ctx#>)
is used to describe the context object. The Bibo ontology (L<http://purl.org/ontology/bibo/>)
and Dublin Core (L<http://purl.org/dc/terms/>) are used to describe the work itself,
with data being "back-projected" from the context object where not too complicated.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::Format>,
L<HTML::Microformats>.

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

