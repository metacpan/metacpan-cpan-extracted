=head1 NAME

HTML::Microformats::Format::hCard::TypedField - helper for hCards; handles value plus type properties

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

package HTML::Microformats::Format::hCard::TypedField;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Format::hCard;
use HTML::Microformats::Utilities qw(searchClass stringify);

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hCard::TypedField::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hCard::TypedField::VERSION   = '0.105';
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

	my $hclass = 'tel';
	$hclass = $1 if $class =~ /::([^:]+)$/;

	my $clone = $element->cloneNode(1);	
	$self->_expand_patterns($clone);
	$self->_simple_parse($clone);
	
	unless (length $self->{'DATA'}->{'value'} or $hclass eq 'label')
	{
		if ($element->hasAttribute('href'))
		{
			$self->{'DATA'}->{'value'} = $self->context->uri( $element->getAttribute('href') );
		}
		elsif ($element->hasAttribute('src'))
		{
			$self->{'DATA'}->{'value'} = $self->context->uri( $element->getAttribute('src') );
		}
	}
	unless (length $self->{'DATA'}->{'value'})
	{
		my @types = searchClass('type', $clone);
		foreach my $type (@types)
		{
			$type->parentNode->removeChild($type);
		}
		$self->{'DATA'}->{'value'} = stringify($clone, {'value-title'=>'allow'});
		$self->{'DATA'}->{'value'} =~ s/(^\s+|\s+$)//g;
	}

	$self->_fix_value_uri;
	
	return $self;
}

sub _fix_value_uri
{
	my $self  = shift;
	# no-op. override in descendent classes.
}

sub format_signature
{
	my $self  = shift;
	my $vcard = 'http://www.w3.org/2006/vcard/ns#';
	my $vx    = 'http://buzzword.org.uk/rdf/vcardx#';
	
	my $package = $self;
	$package = ref $package if ref $package;
	
	my $hclass = 'tel';
	$hclass = $1 if $package =~ /::([^:]+)$/;

	my $u = $hclass =~ m'^(tel|email)$'i ? 'u' : '';

	return {
		'root' => $hclass,
		'classes' => [
			['type',  '*',  {'value-title'=>'allow'}],
			['value', '&v'.$u, {'value-title'=>($hclass eq 'tel' ? 'allow' : undef)}],
		],
		'options' => {
			'no-destroy' => ['adr', 'geo']
		},
		'rdf:type' => [ (($hclass =~ /^(tel|email|label)$/) ? $vcard : $vx).ucfirst $hclass ] ,
		'rdf:property' => {
			'type'  => { 'literal' => ["${vx}usage"] } ,
			'value' => { 'literal' => ["http://www.w3.org/1999/02/22-rdf-syntax-ns#value"] , 'resource' => ["http://www.w3.org/1999/02/22-rdf-syntax-ns#value"] } ,
		},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);
	
	my @types;
	foreach my $type (@{ $self->data->{'type'} })
	{
		if ($type =~ /^(dom|home|intl|parcel|postal|pref|work|video|x400|voice|PCS|pager|msg|modem|ISDN|internet|fax|cell|car|BBS)$/i)
		{
			my $canon = ucfirst lc $1;
			$canon = uc $canon if $canon=~ /(pcs|bbs|isdn)/i;
			
			push @types, {
					'value' => 'http://www.w3.org/2006/vcard/ns#'.$canon,
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
	
	return $self;
}

sub profiles
{
	return HTML::Microformats::Format::hCard::profiles(@_);
}

1;
