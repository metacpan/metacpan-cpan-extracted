=head1 NAME

HTML::Microformats::Format::hCard::org - helper for hCards; handles the org property

=head1 DESCRIPTION

Technically, this inherits from HTML::Microformats::Format, so can be used in the
same way as any of the other microformat module, though I don't know why you'd
want to.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>,
L<HTML::Microformats::Format::hCard>.

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

package HTML::Microformats::Format::hCard::org;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Format::hCard;
use HTML::Microformats::Utilities qw(stringify);

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hCard::org::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hCard::org::VERSION   = '0.105';
}

sub new
{
	my ($class, $element, $context) = @_;
	my $cache = $context->cache;
	
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
	
	if ($self->element->getAttribute('class') =~ /\b(org)\b/)
	{
		unless (defined $self->data->{'organization-name'}
		or defined $self->data->{'organization-unit'}
		or defined $self->data->{'x-vat-number'}
		or defined $self->data->{'x-charity-number'}
		or defined $self->data->{'x-company-number'})
		{
			$self->{'DATA'}->{'organization-name'} = stringify($clone, 'value');
		}
	}
	
	return $self;
}

sub format_signature
{
	my $self  = shift;
	my $vcard = 'http://www.w3.org/2006/vcard/ns#';
	my $vx    = 'http://buzzword.org.uk/rdf/vcardx#';

	return {
		'root' => 'org',
		'classes' => [
			['organization-name',   '?'],
			['organization-unit',   '*'],
			['x-vat-number',        '?'],
			['x-charity-number',    '?'],
			['x-company-number',    '?'],
			['vat-number',          '?', {'use-key'=>'x-vat-number'}],
			['charity-number',      '?', {'use-key'=>'x-charity-number'}],
			['company-number',      '?', {'use-key'=>'x-company-number'}],
		],
		'options' => {
			'no-destroy' => ['adr', 'geo']
		},
		'rdf:type' => ["${vcard}Organization"] ,
		'rdf:property' => {
			'organization-name'   => { 'literal' => ["${vcard}organization-name"] } ,
			'organization-unit'   => { 'literal' => ["${vcard}organization-unit"] } ,
			'x-vat-number'        => { 'literal' => ["${vx}x-vat-number"] } ,
			'x-charity-number'    => { 'literal' => ["${vx}x-charity-number"] } ,
			'x-company-number'    => { 'literal' => ["${vx}x-company-number"] } ,
		},
	};
}

sub profiles
{
	return HTML::Microformats::Format::hCard::profiles(@_);
}

1;
