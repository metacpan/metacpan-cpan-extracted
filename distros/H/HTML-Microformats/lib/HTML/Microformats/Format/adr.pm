=head1 NAME

HTML::Microformats::Format::adr - the adr microformat

=head1 SYNOPSIS

 use Data::Dumper;
 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::adr;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @adrs    = HTML::Microformats::Format::adr->extract_all(
                   $dom->documentElement, $context);
 foreach my $adr (@adrs)
 {
   print Dumper($adr->data) . "\n";
 }

=head1 DESCRIPTION

HTML::Microformats::Format::adr inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::Format::adr;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use Locale::Country qw(country2code LOCALE_CODE_ALPHA_2);

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::adr::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::adr::VERSION   = '0.105';
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
		'id'         => $context->make_bnode($element) ,
		};
	
	bless $self, $class;
	
	my $clone = $element->cloneNode(1);	
	$self->_expand_patterns($clone);
	$self->_simple_parse($clone);

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub format_signature
{
	my $vcard = 'http://www.w3.org/2006/vcard/ns#';
	my $geo   = 'http://www.w3.org/2003/01/geo/wgs84_pos#';

	return {
		'root' => 'adr',
		'classes' => [
			['geo',              'm*', {'embedded'=>'geo'}], # extension to the spec
			['post-office-box',  '*'],
			['extended-address', '*'],
			['street-address',   '*'],
			['locality',         '*'],
			['region',           '*'],
			['postal-code',      '*'],
			['country-name',     '*'],
			['type',             '*']  # only allowed when used in hCard. still...
		],
		'options' => {
			'no-destroy' => ['geo']
		},
		'rdf:type' => ["${vcard}Address"] ,
		'rdf:property' => {
			'post-office-box'  => { 'literal'  => ["${vcard}post-office-box"] } ,
			'extended-address' => { 'literal'  => ["${vcard}extended-address"] } ,
			'locality'         => { 'literal'  => ["${vcard}locality"] } ,
			'region'           => { 'literal'  => ["${vcard}region"] } ,
			'postal-code'      => { 'literal'  => ["${vcard}postal-code"] } ,
			'country-name'     => { 'literal'  => ["${vcard}country-name"] } ,
		},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);

	# Map 'type' (only for valid hCard types though)
	my @types;
	foreach my $type (@{ $self->data->{'type'} })
	{
		if ($type =~ /^(dom|home|intl|parcel|postal|pref|work)$/i)
		{
			push @types, {
					'value' => 'http://www.w3.org/2006/vcard/ns#'.(ucfirst lc $1),
					'type'  => 'uri',
				};
		}
	}
	if (@types)
	{
		$model->add_hashref({
			$self->id =>
				{ 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => \@types }
			});
	}
	
	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1),
		RDF::Trine::Node::Resource->new('http://buzzword.org.uk/rdf/vcardx#represents-location'),
		$self->id(1, 'place'),
		));

	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1, 'place'),
		RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
		RDF::Trine::Node::Resource->new('http://www.w3.org/2003/01/geo/wgs84_pos#SpatialThing'),
		));

	foreach my $geo (@{ $self->data->{'geo'} })
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new('http://buzzword.org.uk/rdf/vcardx#geo'),
			$geo->id(1),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, 'place'),
			RDF::Trine::Node::Resource->new('http://www.w3.org/2003/01/geo/wgs84_pos#location'),
			$geo->id(1, 'location'),
			));
	}

	# Some clever additional stuff: figure out what country code they meant!
	foreach my $country (@{ $self->data->{'country-name'} })
	{
		my $code = country2code($country, LOCALE_CODE_ALPHA_2);
		if (defined $code)
		{
			$model->add_hashref({
				$self->id(0, 'place') =>
					{ 'http://www.geonames.org/ontology#inCountry' => [{ 'type'=>'uri', 'value'=>'http://ontologi.es/place/'.(uc $code) }] }
				});
		}
	}

	return $self;
}

sub profiles
{
	my $class = shift;
	return qw(http://purl.org/uF/adr/0.9/
		http://microformats.org/profile/hcard
		http://ufs.cc/x/hcard
		http://microformats.org/profile/specs
		http://ufs.cc/x/specs
		http://www.w3.org/2006/03/hcard
		http://purl.org/uF/hCard/1.0/
		http://purl.org/uF/2008/03/);
}

1;

=head1 MICROFORMAT

HTML::Microformats::Format::adr supports adr as described at
L<http://microformats.org/wiki/adr>, with the following additions:

=over 4

=item * 'type' property

This module is used by HTML::Microformats::Format::hCard to handle addresses
within the hCard microformat. hCard addresses include a 'type' property
indicating the address type (e.g. home, work, etc). This module supports
the 'type' property whether or the address is part of an hCard. 

=item * Embedded geo microformat

If an instance of the geo microformat is found embedded within an address,
that geographic location will be associated with the address.

=back

=head1 RDF OUTPUT

Data is returned using the W3C's vCard vocabulary
(L<http://www.w3.org/2006/vcard/ns#>) and occasional other terms.

Like how HTML::Microformats::Format::hCard differentiates between the business card
and the entity represented by the card, this module differentiates between the
address and the location represented by it. The former is an abstract social 
construction, its definition being affected by ephemeral political boundaries;
the latter is a physical place. Theoretically multiple addresses could represent the
same, or overlapping locations, though this module does not generate any data
where that is the case.

Where possible, the module uses Locale::Country to determine the
two letter ISO code for the country of the location, and include this in the
RDF output.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::Format>,
L<HTML::Microformats>,
L<HTML::Microformats::Format::hCard>,
L<HTML::Microformats::Format::geo>.

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

