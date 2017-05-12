=head1 NAME

HTML::Microformats::Format::XOXO - the XOXO microformat

=head1 SYNOPSIS

 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::XOXO;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @objects = HTML::Microformats::Format::XOXO->extract_all(
                   $dom->documentElement, $context);
 my $list = $objects[0];
 
 # Let's assume this structure:
 #
 # <ol class="xoxo people">
 #   <li>
 #     <a href="http://tobyinkster.co.uk/">Toby Inkster</a>
 #     <dl>
 #       <dt>Eye colour</dt>
 #       <dd>Blue</dt>
 #       <dt>Hair colour</dt>
 #       <dd>Blonde</dt>
 #       <dd>Brown</dt>
 #     </dl>
 #   </li>
 # </ol>
 
 print $list->data->as_array->[0]->get_link_title;
 # Toby Inkster
 print $list->data->as_array->[0]->get_properties
      ->get_value('Eye colour')->[0];
 # Blue
 print join '-', $list->data->as_array->[0]
      ->get_value('Hair colour');
 # Blonde-Brown

=head1 DESCRIPTION

HTML::Microformats::Format::XOXO inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

Unlike most of the modules in the HTML::Microformats suite,
the C<data> method returns an HTML::Microformats::Format::XOXO::UL,
HTML::Microformats::Format::XOXO::OL or HTML::Microformats::Format::XOXO::DL
object, rather than a plain hashref.

=cut

package HTML::Microformats::Format::XOXO;

use base qw(HTML::Microformats::Format);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Utilities qw(stringify xml_stringify);
use JSON qw/to_json/;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::XOXO::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::XOXO::VERSION   = '0.105';
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
	
	if ($element->hasAttribute('id') && length $element->getAttribute('id'))
	{
		$self->{'id'} = $context->uri('#' . $element->getAttribute('id'));
	}
	else
	{
		$self->{'id'} = $context->make_bnode($element);
	}
	
	return undef unless $element->localname =~ /^[DOU]L$/i;
	$self->{'DATA'} = $self->_parse_list($element->cloneNode(1));

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub _parse_list
{
	my ($self, $e) = @_;
	
	if (lc $e->localname eq 'ul')
		{ return HTML::Microformats::Format::XOXO::UL->parse($e, $self); }
	elsif (lc $e->localname eq 'ol')
		{ return HTML::Microformats::Format::XOXO::OL->parse($e, $self); }
	elsif (lc $e->localname eq 'dl')
		{ return HTML::Microformats::Format::XOXO::DL->parse($e, $self); }
	
	return undef;
}

sub format_signature
{
	return {
		'root'         => 'xoxo',
		'classes'      => [],
		'options'      => {},
		'rdf:type'     => [] ,
		'rdf:property' => {},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1),
		RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
		RDF::Trine::Node::Resource->new('http://purl.org/dc/dcmitype/Dataset'),
		));

	$model->add_statement(RDF::Trine::Statement->new(
		$self->id(1),
		RDF::Trine::Node::Resource->new('http://open.vocab.org/terms/json'),
		$self->_make_literal( to_json($self, {canonical=>1,convert_blessed=>1}) ),
		));

	return $self;
}

sub profiles
{
	return qw(http://microformats.org/profile/xoxo
		http://ufs.org/x/xoxo
		http://microformats.org/profile/specs
		http://ufs.org/x/specs
		http://purl.org/uF/2008/03/);
}

1;

package HTML::Microformats::Format::XOXO::AbstractList;

use strict qw(subs vars); no warnings;
use 5.010;

sub parse
{
	my ($class, $e, $xoxo) = @_;
	my @items;
	
	foreach my $li ($e->getChildrenByTagName('li'))
		{ push @items, HTML::Microformats::Format::XOXO::LI->parse($li, $xoxo); }
	
	bless \@items, $class;
}

sub TO_JSON
{
	return [ @{$_[0]} ];
}

sub as_array
{
	my ($self) = @_;
	return wantarray ? @$self : $self;
}

1;

=head2 HTML::Microformats::Format::XOXO::DL

Represents an HTML DL element.

=over 4

=item C<< $dl->get_values($key) >>

Treating a DL as a key-value structure, returns a list of values for a given key.
Each value is an HTML::Microformats::Format::XOXO::DD object.

=item C<< $dl->as_hash >>

Returns a hash of keys pointing to arrayrefs of values, where each value is an
HTML::Microformats::Format::XOXO::DD object.

=item C<< $dl->as_array >>

Logically what you think get_values("*") might do.

=back

=cut

package HTML::Microformats::Format::XOXO::DL;

use base qw[HTML::Microformats::Format::XOXO::AbstractList];
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Utilities qw(stringify xml_stringify);

sub parse
{
	my ($class, $e, $xoxo) = @_;
	my $dict = {};
	
	my $term;
	foreach my $kid ($e->childNodes)
	{
		next unless $kid->isa('XML::LibXML::Element');
		
		if ($kid->localname =~ /^DT$/i)
		{
			$term = stringify($kid);
			if ($kid->hasAttribute('id'))
			{
				$dict->{$term}->{'id'} = $kid->getAttribute('id');
			}
		}
		elsif (defined $term)
		{
			push @{ $dict->{$term}->{'items'} }, HTML::Microformats::Format::XOXO::DD->parse($kid, $xoxo);
		}
	}
	
	bless $dict, $class;
}

sub TO_JSON
{
	my $self = shift;
	my $rv = {};
	while (my ($k, $v) = each %$self)
	{
		$rv->{$k} = $v->{'items'};
	}
	return $rv;
}

sub get_values
{
	my ($self, $key) = @_;
	return wantarray ? @{ $self->{$key}->{'items'} } : $self->{$key}->{'items'}
		if defined $self->{$key}->{'items'};
}

sub as_hash
{
	my ($self) = @_;
	return $self->TO_JSON;
}

sub as_array
{
	my ($self, $key) = @_;
	my @rv;
	foreach my $key (sort keys %$self)
	{
		push @rv, @{ $self->{$key}->{'items'} };
	}
	return wantarray ? @rv : \@rv;
}

1;

=head2 HTML::Microformats::Format::XOXO::UL

Represents an HTML UL element.

=over 4

=item C<< $ul->as_array >>

Returns an array of values, where each is a HTML::Microformats::Format::XOXO::LI object.

=back

=cut

package HTML::Microformats::Format::XOXO::UL;

use base qw(HTML::Microformats::Format::XOXO::AbstractList);
use strict qw(subs vars); no warnings;
use 5.010;

1;

=head2 HTML::Microformats::Format::XOXO::OL

Represents an HTML OL element.

=over 4

=item C<< $ol->as_array >>

Returns an array of values, where each is a HTML::Microformats::Format::XOXO::LI object.

=back

=cut

package HTML::Microformats::Format::XOXO::OL;

use base qw(HTML::Microformats::Format::XOXO::AbstractList);
use strict qw(subs vars); no warnings;
use 5.010;

1;

package HTML::Microformats::Format::XOXO::AbstractListItem;

use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Utilities qw(stringify xml_stringify);

our $for_get_them_not = 'a|dl|li|ol|ul';

sub parse
{
	my ($class, $e, $xoxo) = @_;
	my $self = bless {}, $class;
	
	my $a  = $self->_get_them($e, 'a');
	my $dl = $self->_get_them($e, 'dl');
	my $l  = $self->_get_them($e, 'ol|ul');
	
	if ($a)
	{
		$self->{'url'}   = $xoxo->context->uri($a->getAttribute('href'))
			if $a->hasAttribute('href');
		$self->{'type'}  = $a->getAttribute('type')
			if $a->hasAttribute('type');
		$self->{'rel'}   = $a->getAttribute('rel')
			if $a->hasAttribute('rel');
		$self->{'title'} = $a->getAttribute('title') || stringify($a);
	}
	
	if ($dl)
	{
		$self->{'properties'} = HTML::Microformats::Format::XOXO::DL->parse($dl, $xoxo);
		$dl->parentNode->removeChild($dl);
	}

	if (defined $l && lc $l->localname eq 'ul')
	{
		$self->{'children'} = HTML::Microformats::Format::XOXO::UL->parse($l, $xoxo);
		$l->parentNode->removeChild($l);
	}
	elsif (defined $l && lc $l->localname eq 'ol')
	{
		$self->{'children'} = HTML::Microformats::Format::XOXO::OL->parse($l, $xoxo);
		$l->parentNode->removeChild($l);
	}
	
	$self->{'text'} = stringify($e);
	$self->{'html'} = xml_stringify($e);

	return $self;
}

sub _get_them
{
	my ($self, $e, $pattern) = @_;
	
	my @rv;
	my @check = $e->childNodes;
	
	while (@check)
	{
		my $elem = shift @check;
		next unless $elem->isa('XML::LibXML::Element');
		
		if ($elem->localname =~ /^($pattern)$/i)
		{
			if (wantarray)
				{ push @rv, $elem; }
			else
				{ return $elem; }
		}
		if ($elem->localname !~ /^($for_get_them_not)$/i)
		{
			unshift @check, $elem->childNodes;
		}
	}
	
	if (wantarray)
		{ return @rv; }
	else
		{ return undef; }
}

sub TO_JSON
{
	my %rv = %{$_[0]};
	delete $rv{'html'};
	return \%rv;
}

sub get_link_href
{
	my ($self) = @_;
	return $self->{'url'};
}

sub get_link_rel
{
	my ($self) = @_;
	return $self->{'rel'};
}

sub get_link_type
{
	my ($self) = @_;
	return $self->{'type'};
}

sub get_link_title
{
	my ($self) = @_;
	return $self->{'title'};
}

sub get_text
{
	my ($self) = @_;
	return $self->{'text'};
}

sub get_html
{
	my ($self) = @_;
	return $self->{'html'};
}

sub get_properties
{
	my ($self) = @_;
	return $self->{'properties'};
}

sub get_children
{
	my ($self) = @_;
	return $self->{'children'};
}

sub get_value
{
	my ($self, $key) = @_;
	return $self->get_properties->get_values($key)
		if $self->get_properties;
}

1;

=head2 HTML::Microformats::Format::XOXO::LI

Represents an HTML LI element.

=over 4

=item C<< $li->get_link_href >>

Returns the URL linked to by the B<first> link found within the item.

=item C<< $li->get_link_rel >>

Returns the value of the rel attribute of the first link found within the item.
This is an unparsed string.

=item C<< $li->get_link_type >>

Returns the value of the type attribute of the first link found within the item.
This is an unparsed string.

=item C<< $li->get_link_title >>

Returns the value of the rel attribute of the first link found within the item
if present; the link text otherwise.

=item C<< $li->get_text >>

Returns the value of the text in the LI element B<except> for the first DL
element within the LI, and the first UL or OL element.

=item C<< $li->get_html >>

Returns the HTML code in the LI element B<except> for the first DL
element within the LI, and the first UL or OL element.

=item C<< $li->get_properties >>

Returns an HTML::Microformats::Format::XOXO::DL object representing the first
DL element within the LI.

=item C<< $li->get_children >>

Returns an HTML::Microformats::Format::XOXO::OL or HTML::Microformats::Format::XOXO::UL
object representing the first OL or UL element within the LI.

=item C<< $li->get_value($key) >>

A shortcut for C<< $li->get_properties->get_values($key) >>.

=back

=cut

package HTML::Microformats::Format::XOXO::LI;

use base qw(HTML::Microformats::Format::XOXO::AbstractListItem);
use strict qw(subs vars); no warnings;
use 5.010;

1;

=head2 HTML::Microformats::Format::XOXO::DD

This has an identical interface to HTML::Microformats::Format::XOXO::LI.

=cut

package HTML::Microformats::Format::XOXO::DD;

use base qw(HTML::Microformats::Format::XOXO::AbstractListItem);
use strict qw(subs vars); no warnings;
use 5.010;

1;

=head1 MICROFORMAT

HTML::Microformats::Format::XOXO supports XOXO as described at
L<http://microformats.org/wiki/xoxo>.

=head1 RDF OUTPUT

XOXO does not map especially naturally to RDF, so this module returns
the data as a JSON literal using the property L<http://open.vocab.org/terms/json>.

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

