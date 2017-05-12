=head1 NAME

HTML::Microformats::Format::hReviewAggregate - the hReview-aggregate microformat

=head1 SYNOPSIS

 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::hReviewAggregate;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @reviews = HTML::Microformats::Format::hReviewAggregate->extract_all(
                   $dom->documentElement, $context);
 foreach my $review (@reviews)
 {
   print Dumper($review->data) . "\n";
 }

=head1 DESCRIPTION

HTML::Microformats::Format::hReviewAggregate inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::Format::hReviewAggregate;

use base qw(HTML::Microformats::Format::hReview);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Utilities qw(stringify searchClass);
use HTML::Microformats::Format::hReview::rating;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hReviewAggregate::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hReviewAggregate::VERSION   = '0.105';
}

sub new
{
	my ($class, $element, $context, %options) = @_;
	my $cache = $context->cache;
	
	return $cache->get($context, $element, $class)
		if defined $cache && $cache->get($context, $element, $class);
	
	my $self = {
		'element'    => $element ,
		'context'    => $context ,
		'cache'      => $cache ,
		'id'         => $context->make_bnode($element) ,
		'id.holder'  => $context->make_bnode ,
		};
	
	bless $self, $class;
	
	my $clone = $element->cloneNode(1);	
	$self->_expand_patterns($clone);
	$self->_simple_parse($clone);
	
	$self->_fallback_item($clone)->_auto_detect_type;

	$self->{'DATA'}->{'rating'} =
		[ HTML::Microformats::Format::hReview::rating->extract_all($clone, $context) ];

	$cache->set($context, $element, $class, $self)
		if defined $cache;
	
	return $self;
}

sub format_signature
{
	my $self  = shift;
	
	my $rev     = 'http://www.purl.org/stuff/rev#';
	my $hreview = 'http://ontologi.es/hreview#';

	my $rv = {
		'root'    => 'hreview-aggregate',
		'classes' => [
			['item',        'm1',   {'embedded'=>'hProduct hAudio hEvent hCard'}], # lowercase 'm' = don't try plain string.
			['summary',     '1'],
			['type',        '?'],
			['bookmark',    'ru?',  {'use-key'=>'permalink'}],
			['description', 'H*'],
			['rating',      '*#'],
			['count',       'n?'],
			['votes',       'n?'],
		],
		'options' => {
			'rel-tag'     => 'tag',
			'rel-license' => 'license',
		},
		'rdf:type' => ["${hreview}Aggregate"] ,
		'rdf:property' => {
			'description'   => { 'literal'  => ["${rev}text"] },
			'type'          => { 'literal'  => ["${rev}type"] },
			'summary'       => { 'literal'  => ["${rev}title", "http://www.w3.org/2000/01/rdf-schema#label"] },
			'rating'        => { 'resource' => ["${hreview}rating"] },
			'tag'           => { 'resource' => ['http://www.holygoat.co.uk/owl/redwood/0.1/tags/taggedWithTag'] },
			'license'       => { 'resource' => ["http://www.iana.org/assignments/relation/license", "http://creativecommons.org/ns#license"] },
			'permalink'     => { 'resource' => ["http://www.iana.org/assignments/relation/self"] },
			'count'         => { 'literal'  => ["${hreview}count"] },
			'votes'         => { 'literal'  => ["${hreview}votes"] },
		},
	};
		
	return $rv;
}

sub profiles
{
	my $class = shift;
	return qw(http://microformats.org/wiki/hreview-aggregate);
}

1;

=head1 MICROFORMAT

HTML::Microformats::Format::hReviewAggregate supports hReview-aggregate 0.2 as described at
L<http://microformats.org/wiki/hreview-aggregate> with the following differences:

=over 4

=item * hAudio

hAudio microformats can be used as the reviewed item.

=item * hReview properties

A few properties are supported from (non-aggregate) hReview - e.g.
'bookmark', 'tag', 'description' and 'type'.

=back

=head1 RDF OUTPUT

L<http://www.purl.org/stuff/rev#>, L<http://ontologi.es/hreview#>.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::Format>,
L<HTML::Microformats::Format::hReview>,
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

