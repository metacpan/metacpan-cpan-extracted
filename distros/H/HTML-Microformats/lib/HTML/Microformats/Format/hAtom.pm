=head1 NAME

HTML::Microformats::Format::hAtom - the hAtom microformat

=head1 SYNOPSIS

 use Data::Dumper;
 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::hAtom;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @feeds   = HTML::Microformats::Format::hAtom->extract_all(
                   $dom->documentElement, $context);
 foreach my $feed (@feeds)
 {
   foreach my $entry ($feed->get_entry)
   {
     print $entry->get_link . "\n";
   }
 }

=head1 DESCRIPTION

HTML::Microformats::Format::hAtom inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=head2 Additional Method

=over

=item * C<< to_atom >>

This method exports the data as an XML file containing an Atom <feed>.
It requires L<XML::Atom::FromOWL> to work, and will throw an error at
run-time if it's not available.

=back

=cut

package HTML::Microformats::Format::hAtom;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Utilities qw(searchAncestorClass);
use HTML::Microformats::Datatype::String qw(isms);
use HTML::Microformats::Format::hCard;
use HTML::Microformats::Format::hEntry;
use HTML::Microformats::Format::hNews;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hAtom::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hAtom::VERSION   = '0.105';
}
our $HAS_ATOM_EXPORT;
BEGIN
{
	local $@ = undef;
	eval 'use XML::Atom::FromOWL;';
	$HAS_ATOM_EXPORT = 1
		if XML::Atom::FromOWL->can('new'); 
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
		
	my $clone = $self->{'element'}->cloneNode(1);	
	$self->_expand_patterns($clone);
	$self->_simple_parse($clone);
	
	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub extract_all
{
	my ($class, $element, $context) = @_;
	
	my @feeds = HTML::Microformats::Format::extract_all($class, $element, $context);
	
	if ($element->tagName eq 'html' || !@feeds)
	{
		my @entries = HTML::Microformats::Format::hEntry->extract_all($element, $context);
		my $orphans = 0;
		foreach my $entry (@entries)
		{
			$orphans++ unless searchAncestorClass('hfeed', $entry->element);
		}
		if ($orphans)
		{
			my $slurpy = $class->new($element, $context);
			unshift @feeds, $slurpy;
		}
	}
	
	return @feeds;
}

sub format_signature
{
	my $awol = 'http://bblfish.net/work/atom-owl/2006-06-06/#';
	my $ax   = 'http://buzzword.org.uk/rdf/atomix#';
	my $iana = 'http://www.iana.org/assignments/relation/';
	my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
	
	return {
		'root' => ['hfeed'],
		'classes' => [
			['hentry',  'm*',   {'embedded'=>'hEntry', 'use-key'=>'entry'}],
		],
		'options' => {
			'rel-tag' => 'category',
		},
		'rdf:type' => ["${awol}Feed"] ,
		'rdf:property' => {
			'entry'       => { resource => ["${awol}entry"] } ,
			'category'    => { resource => ["${awol}category"] } ,
			},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);

	my $awol = 'http://bblfish.net/work/atom-owl/2006-06-06/#';
	my $ax   = 'http://buzzword.org.uk/rdf/atomix#';
	my $iana = 'http://www.iana.org/assignments/relation/';
	my $rdfs = 'http://www.w3.org/2000/01/rdf-schema#';
	my $rdf  = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
	
	foreach my $author (@{ $self->data->{'author'} })
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${awol}author"),
			$author->id(1, 'holder'),
			));
		$author->add_to_model($model);
	}

	return $self;
}

sub to_atom
{
	my ($self) = @_;
	die "Need XML::Atom::FromOWL to export Atom.\n" unless $HAS_ATOM_EXPORT;
	my $exporter = XML::Atom::FromOWL->new;
	return $exporter->export_feed($self->model, $self->id(1))->as_xml;
}

sub profiles
{
	my @p = qw();
	push @p, HTML::Microformats::Format::hEntry->profiles;
	push @p, HTML::Microformats::Format::hNews->profiles;
	return @p;
}

1;

=head1 MICROFORMAT

HTML::Microformats::Format::hAtom supports hAtom as described at
L<http://microformats.org/wiki/hatom>, with the following additions:

=over 4

=item * Embedded rel-enclosure microformat

hAtom entries may use rel-enclosure to specify entry enclosures.

=item * Threading support

An entry may use rel="in-reply-to" to indicate another entry or a document that
this entry is considered a reply to.

An entry may use class="replies hfeed" to provide an hAtom feed of responses to it.

=back

=head1 RDF OUTPUT

Data is returned using Henry Story's AtomOWL vocabulary
(L<http://bblfish.net/work/atom-owl/2006-06-06/#>), Toby Inkster's
AtomOWL extensions (L<http://buzzword.org.uk/rdf/atomix#>) and
the IANA registered relationship URIs (L<http://www.iana.org/assignments/relation/>).

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::Format>,
L<HTML::Microformats>,
L<HTML::Microformats::Format::hEntry>,
L<HTML::Microformats::Format::hNews>.

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
