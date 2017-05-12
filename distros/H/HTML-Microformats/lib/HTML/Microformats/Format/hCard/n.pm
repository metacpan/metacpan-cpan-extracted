=head1 NAME

HTML::Microformats::Format::hCard::n - helper for hCards; handles the n property

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

package HTML::Microformats::Format::hCard::n;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Format::hCard;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hCard::n::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hCard::n::VERSION   = '0.105';
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
	
	return $self;
}

sub format_signature
{
	my $self  = shift;
	my $vcard = 'http://www.w3.org/2006/vcard/ns#';
	my $vx    = 'http://buzzword.org.uk/rdf/vcardx#';

	return {
		'root' => 'n',
		'classes' => [
			['additional-name',  '*'],
			['family-name',      '*'],
			['given-name',       '*'],
			['honorific-prefix', '*'],
			['honorific-suffix', '*'],
			['initial',          '*'], # extension
		],
		'options' => {
			'no-destroy' => ['adr', 'geo']
		},
		'rdf:type' => ["${vcard}Name"] ,
		'rdf:property' => {
			'additional-name'   => { 'literal' => ["${vcard}additional-name"] } ,
			'family-name'       => { 'literal' => ["${vcard}family-name"] } ,
			'given-name'        => { 'literal' => ["${vcard}given-name"] } ,
			'honorific-prefix'  => { 'literal' => ["${vcard}honorific-prefix"] } ,
			'honorific-suffix'  => { 'literal' => ["${vcard}honorific-suffix"] } ,
			'honorific-initial' => { 'literal' => ["${vx}initial"] } ,
		},
	};
}

sub profiles
{
	return HTML::Microformats::Format::hCard::profiles(@_);
}

1;
