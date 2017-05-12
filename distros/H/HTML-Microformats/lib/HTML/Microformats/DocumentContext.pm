package HTML::Microformats::DocumentContext;

use strict qw(subs vars); no warnings;
use 5.010;

use Data::UUID;
use HTML::Microformats::ObjectCache;
use HTML::Microformats::Utilities qw'searchAncestorTag';
use URI;
use XML::LibXML qw(:all);

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::DocumentContext::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::DocumentContext::VERSION   = '0.105';
}

sub new
{
	my ($class, $document, $uri, $cache) = @_;
	
	$cache ||= HTML::Microformats::ObjectCache->new;
	
	my $self = {
		'document' => $document ,
		'uri'      => $uri ,
		'profiles' => [] ,
		'cache'    => $cache ,
		};
	bless $self, $class;
	
	foreach my $e ($document->getElementsByTagName('*'))
	{
		my $np = $e->nodePath;
		$np =~ s?\*/?\*\[1\]/?g;
		$e->setAttribute('data-cpan-html-microformats-nodepath', $np)
	}

	($self->{'bnode_prefix'} = Data::UUID->new->create_hex) =~ s/^0x//;

	$self->_process_langs($document->documentElement);
	$self->_detect_profiles;
	
	return $self;
}

sub cache
{
	return $_[0]->{'cache'};
}

sub document
{
	return $_[0]->{'document'};
}

sub uri
{
	my $this  = shift;
	my $param = shift || '';
	my $opts  = shift || {};
	
	if ((ref $opts) =~ /^XML::LibXML/)
	{
		my $x = {'element' => $opts};
		$opts = $x;
	}
	
	if ($param =~ /^([a-z][a-z0-9\+\.\-]*)\:/i)
	{
		# seems to be an absolute URI, so can safely return "as is".
		return $param;
	}
	elsif ($opts->{'require-absolute'})
	{
		return undef;
	}
	
	my $base = $this->{'uri'};
	if ($opts->{'element'})
	{
		$base = $this->get_node_base($opts->{'element'});
	}
	
	my $rv = URI->new_abs($param, $base)->canonical->as_string;

	while ($rv =~ m!^(http://.*)(\.\./|\.)+(\.\.|\.)?$!i)
	{
		$rv = $1;
	}
	
	return $rv;
}

sub document_uri
{
	my $self = shift;
	return $self->{'document_uri'} || $self->uri;
}

sub make_bnode
{
	my ($self, $elem) = @_;
	
#	if (defined $elem && $elem->hasAttribute('id'))
#	{
#		my $uri = $self->uri('#' . $elem->getAttribute('id'));
#		return 'http://thing-described-by.org/?'.$uri;
#	}
	
	return sprintf('_:B%s%04d', $self->{'bnode_prefix'}, $self->{'next_bnode'}++);
}

sub profiles
{
	return @{ $_[0]->{'profiles'} };
}

sub has_profile
{
	my $self = shift;
	foreach my $requested (@_)
	{
		foreach my $available ($self->profiles)
		{
			return 1 if $available eq $requested;
		}
	}
	return 0;
}

sub add_profile
{
	my $self = shift;
	foreach my $p (@_)
	{
		push @{ $self->{'profiles'} }, $p
			unless $self->has_profile($p);
	}
}

sub representative_hcard
{
	my $self = shift;
	
	unless ($self->{'representative_hcard'})
	{
		my @hcards = HTML::Microformats::Format::hCard->extract_all($self->document->documentElement, $self);
		HCARD: foreach my $hc (@hcards)
		{
			next unless ref $hc;
			if (defined $hc->data->{'uid'}
			and $hc->data->{'uid'} eq $self->document_uri)
			{
				$self->{'representative_hcard'} = $hc;
				last HCARD;
			}
		}
		unless ($self->{'representative_hcard'})
		{
			HCARD: foreach my $hc (@hcards)
			{
				next unless ref $hc;
				if ($hc->data->{'_has_relme'})
				{
					$self->{'representative_hcard'} = $hc;
					last HCARD;
				}
			}
		}
#		unless ($self->{'representative_hcard'})
#		{
#			$self->{'representative_hcard'} = $hcards[0] if @hcards;
#		}
		if ($self->{'representative_hcard'})
		{
			$self->{'representative_hcard'}->{'representative'} = 1;
		}
	}
	
	return $self->{'representative_hcard'};
}

sub representative_person_id
{
	my $self     = shift;
	my $as_trine = shift;
	
	my $hcard = $self->representative_hcard;
	if ($hcard)
	{
		return $hcard->id($as_trine, 'holder');
	}
	
	unless (defined $self->{'representative_person_id'})
	{
		$self->{'representative_person_id'} = $self->make_bnode;
	}
	
	if ($as_trine)
	{
		return ($self->{'representative_person_id'}  =~ /^_:(.*)$/) ?
				 RDF::Trine::Node::Blank->new($1) :
				 RDF::Trine::Node::Resource->new($self->{'representative_person_id'});
	}
	
	return $self->{'representative_person_id'};
}

sub contact_hcard
{
	my $self = shift;
	
	unless ($self->{'contact_hcard'})
	{
		my @hcards = HTML::Microformats::Format::hCard->extract_all($self->document->documentElement, $self);
		my ($shallowest, $shallowest_depth);
		HCARD: foreach my $hc (@hcards)
		{
			next unless ref $hc;
			
			my $address = searchAncestorTag('address', $hc->element);
			next unless defined $address;
			
			my @bits = split m'/', $address;
			my $address_depth = scalar(@bits);
			if ($address_depth < $shallowest_depth
			|| !defined $shallowest)
			{
				$shallowest_depth = $address_depth;
				$shallowest = $hc;
			}
		}
		$self->{'contact_hcard'} = $shallowest;

		if ($self->{'contact_hcard'})
		{
			$self->{'contact_hcard'}->{'contact'} = 1;
		}
	}

	return $self->{'contact_hcard'};
}

sub contact_person_id
{
	my $self     = shift;
	my $as_trine = shift;
	
	my $hcard = $self->contact_hcard;
	if ($hcard)
	{
		return $hcard->id($as_trine, 'holder');
	}
	
	unless (defined $self->{'contact_person_id'})
	{
		$self->{'contact_person_id'} = $self->make_bnode;
	}
	
	if ($as_trine)
	{
		return ($self->{'contact_person_id'}  =~ /^_:(.*)$/) ?
				 RDF::Trine::Node::Blank->new($1) :
				 RDF::Trine::Node::Resource->new($self->{'contact_person_id'});
	}
	
	return $self->{'contact_person_id'};
}

sub _process_langs
{
	my $self = shift;
	my $elem = shift;
	my $lang = shift;

	if ($elem->hasAttributeNS(XML_XML_NS, 'lang'))
	{
		$lang = $elem->getAttributeNS(XML_XML_NS, 'lang');
	}
	elsif ($elem->hasAttribute('lang'))
	{
		$lang = $elem->getAttribute('lang');
	}

	$elem->setAttribute('data-cpan-html-microformats-lang', $lang);	

	foreach my $child ($elem->getChildrenByTagName('*'))
	{
		$self->_process_langs($child, $lang);
	}
}

sub _detect_profiles
{
	my $self = shift;
	
	foreach my $head ($self->document->getElementsByTagNameNS('http://www.w3.org/1999/xhtml', 'head'))
	{
		if ($head->hasAttribute('profile'))
		{
			my @p = split /\s+/, $head->getAttribute('profile');
			foreach my $p (@p)
			{
				$self->add_profile($p) if length $p;
			}
		}
	}
}

1;

__END__

=head1 NAME

HTML::Microformats::DocumentContext - context for microformat objects

=head1 DESCRIPTION

Microformat objects need context when being parsed to properly make sense.
For example, a base URI is needed to resolve relative URI references, and a full
copy of the DOM tree is needed to implement the include pattern.

=head2 Constructor

=over

=item C<< $context = HTML::Microformats::DocumentContext->new($dom, $baseuri) >>

Creates a new context from a DOM document and a base URI.

$dom will be modified, so if you care about keeping it pristine, make a clone first.

=back

=head2 Public Methods

=over

=item C<< $context->cache >>

A Microformat cache for the context. This prevents the same microformat object from
being parsed and reparsed - e.g. an adr parsed first in its own right, and later as a child
of an hCard.

=item C<< $context->document >>

Return the modified DOM document.

=item C<< $context->uri( [$relative_reference] ) >>

Called without a parameter, returns the context's base URI.

Called with a parameter, resolves the URI reference relative to the
base URI.

=item C<< $context->document_uri >>

Returns a URI representing the document itself. (Usually the same as the
base URI.)

=item C<< $context->make_bnode( [$element] ) >>

Mint a blank node identifier or a URI.

If an element is passed, this may be used to construct a URI in some way.

=item C<< $context->profiles >>

A list of profile URIs declared by the document.

=item C<< $context->has_profile(@profiles) >>

Returns true iff any of the profiles in the array are declared by the document.

=item C<< $context->add_profile(@profiles) >>

Declare these additional profiles.

=item C<< $context->representative_hcard >>

Returns the hCard for the person that is "represented by" the page (in the XFN sense),
or undef if no suitable hCard could be found

=item C<< $context->representative_person_id( [$as_trine] ) >>

Equivalent to calling C<< $context->representative_hcard->id($as_trine, 'holder') >>,
however magically works even if $context->representative_hcard returns undef.

=item C<< $context->contact_hcard >>

Returns the hCard for the contact person for the page, or undef if none can be found.

hCards are considered potential contact hCards if they are contained within an HTML
E<lt>addressE<gt> tag, or their root element is an E<lt>addressE<gt> tag. If there
are several such hCards, then the one in the shallowest E<lt>addressE<gt> tag is
used; if there are several E<lt>addressE<gt> tags equally shallow, the first is used.

=item C<< $context->contact_person_id( [$as_trine] ) >>

Equivalent to calling C<< $context->contact_hcard->id($as_trine, 'holder') >>,
however magically works even if $context->contact_hcard returns undef.

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>

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

