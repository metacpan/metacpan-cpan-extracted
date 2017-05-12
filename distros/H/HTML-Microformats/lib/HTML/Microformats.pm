package HTML::Microformats;

use strict qw(subs vars); no warnings;
use 5.010;

use HTML::HTML5::Parser;
use HTML::HTML5::Sanity qw(fix_document);
use HTML::Microformats::DocumentContext;
use HTML::Microformats::Datatype;
use HTML::Microformats::Format;
use JSON;
use RDF::Trine 0.130;
use XML::LibXML;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::VERSION   = '0.105';
}

sub new_document
{
	my $class    = shift;
	my $document = shift;
	my $uri      = shift;
	my %opts     = @_;
	
	my $self = bless {}, $class;
	$self->modules; # force modules to be loaded
	
	if (ref $document && $document->isa('XML::LibXML::Document'))
	{
	}
	elsif ($opts{'type'} =~ /x(ht)?ml/i)
	{
		my $parser = XML::LibXML->new;
		$document  = $parser->parse_string($document);
	}
	else
	{
		my $parser = HTML::HTML5::Parser->new;
		$document  = fix_document( $parser->parse_string($document) );
	}
	
	$self->{'context'} = HTML::Microformats::DocumentContext->new($document, $uri);
	
	return $self;
}

sub profiles
{
	my $self = shift;
	return $self->{'context'}->profiles(@_);
}

sub has_profile
{
	my $self = shift;
	return $self->{'context'}->has_profile(@_);
}

sub add_profile
{
	my $self = shift;
	$self->{'context'}->add_profile(@_);
	return $self;
}

sub assume_profile
{
	my $self = shift;
	
	foreach my $fmt (@_)
	{
		my $profile = $fmt;
		($profile) = "HTML::Microformats::Format::${fmt}"->profiles
			if $fmt !~ ':';
		$self->add_profile($profile);
	}
	
	return $self;
}

sub assume_all_profiles
{
 	my $self = shift;
 	$self->assume_profile($self->formats);
	return $self;
}

sub parse_microformats
{
	my $self = shift;
	return if $self->{'parsed'};
	
	foreach my $fmt ($self->formats)
	{
		my @profiles = "HTML::Microformats::Format::${fmt}"->profiles;
		
		if ($self->has_profile(@profiles))
		{
			my @objects = "HTML::Microformats::Format::${fmt}"->extract_all(
				$self->{'context'}->document->documentElement,
				$self->{'context'});
			$self->{'objects'}->{$fmt} = \@objects;
		}
	}
	
	$self->{'parsed'} = 1;
	return $self;
}

sub clear_microformats
{
 	my $self = shift;
 	$self->{'objects'} = undef;
 	$self->{'context'}->cache->clear;
 	$self->{'parsed'}  = 0;
	return $self;
}

sub objects
{
	my $self = shift;
	my $fmt  = shift;
	$self->parse_microformats;
	return @{ $self->{'objects'}->{$fmt} }
		if wantarray;
	return $self->{'objects'}->{$fmt};
}

sub all_objects
{
	my $self = shift;
	$self->parse_microformats;	
	return $self->{'objects'};
}

sub TO_JSON
{
	return $_[0]->all_objects;
}

sub json
{
	my $self = shift;
	my %opts = @_;
	
	$opts{'convert_blessed'} = 1
		unless defined $opts{'convert_blessed'};

	$opts{'utf8'} = 1
		unless defined $opts{'utf8'};

	return to_json($self->all_objects, \%opts);
}
 
sub model
{
	my $self  = shift;
	my $model = RDF::Trine::Model->temporary_model;
	$self->add_to_model($model);
	return $model;
}

sub serialise_model
{
	my $self = shift;
	
	my %opts = ref $_[0] ? %{ $_[0] } : @_;
	$opts{as} ||= 'Turtle';
	
	my $ser = RDF::Trine::Serializer->new(delete $opts{as}, %opts);
	return $ser->serialize_model_to_string($self->model);
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;
	$self->parse_microformats;
	
	foreach my $fmt ($self->formats)
	{
		foreach my $object (@{ $self->{'objects'}->{$fmt} })
		{
			$object->add_to_model($model);
		}
	}
	
	return $self;
}

use Module::Pluggable
	require     => 1,
	inner       => 0,
	search_path => ['HTML::Microformats::Format'],
	only        => qr/^HTML::Microformats::Format::[^:]+$/,
	sub_name    => 'modules',
	;

sub formats
{
	my $class = shift || __PACKAGE__;
	return
		sort { lc $a cmp lc $b }
		map { s/^HTML::Microformats::Format:://; $_ }
		$class->modules;
}

1;

__END__

=head1 NAME

HTML::Microformats - parse microformats in HTML

=head1 SYNOPSIS

 use HTML::Microformats;
 
 my $doc = HTML::Microformats
             ->new_document($html, $uri)
             ->assume_profile(qw(hCard hCalendar));
 print $doc->json(pretty => 1);
 
 use RDF::TrineShortcuts qw(rdf_query);
 my $results = rdf_query($sparql, $doc->model);
 
=head1 DESCRIPTION

The HTML::Microformats module is a wrapper for parser and handler
modules of various individual microformats (each of those modules
has a name like HTML::Microformats::Format::Foo).

The general pattern of usage is to create an HTML::Microformats
object (which corresponds to an HTML document) using the
C<new_document> method; then ask for the data, as a Perl hashref,
a JSON string, or an RDF::Trine model.

=head2 Constructor

=over 4

=item C<< $doc = HTML::Microformats->new_document($html, $uri, %opts) >>

Constructs a document object.

$html is the HTML or XHTML source (string) or an XML::LibXML::Document.

$uri is the document URI, important for resolving relative URL references.

%opts are additional parameters; currently only one option is defined:
$opts{'type'} is set to 'text/html' or 'application/xhtml+xml', to
control how $html is parsed.

=back

=head2 Profile Management

HTML::Microformats uses HTML profiles (i.e. the profile attribute on the
HTML <head> element) to detect which Microformats are used on a page. Any
microformats which do not have a profile URI declared will not be parsed.

Because many pages fail to properly declare which profiles they use, there
are various profile management methods to tell HTML::Microformats to
assume the presence of particular profile URIs, even if they're actually
missing.

=over 4

=item C<< $doc->profiles >>

This method returns a list of profile URIs declared by the document.

=item C<< $doc->has_profile(@profiles) >>

This method returns true if and only if one or more of the profile URIs
in @profiles is declared by the document.

=item C<< $doc->add_profile(@profiles) >>

Using C<add_profile> you can add one or more profile URIs, and they are
treated as if they were found on the document.

For example:

 $doc->add_profile('http://microformats.org/profile/rel-tag')

This is useful for adding profile URIs declared outside the document itself
(e.g. in HTTP headers).

Returns a reference to the document.

=item C<< $doc->assume_profile(@microformats) >>

For example:

 $doc->assume_profile(qw(hCard adr geo))

This method acts similarly to C<add_profile> but allows you to use
names of microformats rather than URIs.

Microformat names are case sensitive, and must match
HTML::Microformats::Format::Foo module names.

Returns	a reference to the document.

=item C<< $doc->assume_all_profiles >>

This method is equivalent to calling C<assume_profile> for
all known microformats.

Returns	a reference to the document.

=back

=head2 Parsing Microformats

Generally speaking, you can skip this. The C<data>, C<json> and
C<model> methods will automatically do this for you.

=over 4

=item C<< $doc->parse_microformats >>

Scans through the document, finding microformat objects.

On subsequent calls, does nothing (as everything is already parsed).

Returns	a reference to the document.

=item C<< $doc->clear_microformats >>

Forgets information gleaned by C<parse_microformats> and thus allows
C<parse_microformats> to be run again. This is useful if you've modified
added some profiles between runs of C<parse_microformats>.

Returns	a reference to the document.

=back

=head2 Retrieving Data

These methods allow you to retrieve the document's data, and do things
with it.

=over 4

=item C<< $doc->objects($format); >>

$format is, for example, 'hCard', 'adr' or 'RelTag'.

Returns a list of objects of that type. (If called in scalar context,
returns an arrayref.)

Each object is, for example, an HTML::Microformat::hCard object, or an
HTML::Microformat::RelTag object, etc. See the relevent documentation
for details.

=item C<< $doc->all_objects >>

Returns a hashref of data. Each hashref key is the name of a microformat
(e.g. 'hCard', 'RelTag', etc), and the values are arrayrefs of objects.

Each object is, for example, an HTML::Microformat::hCard object, or an
HTML::Microformat::RelTag object, etc. See the relevent documentation
for details.

=item C<< $doc->json(%opts) >>

Returns data roughly equivalent to the C<all_objects> method, but as a JSON
string.

%opts is a hash of options, suitable for passing to the L<JSON>
module's to_json function. The 'convert_blessed' and 'utf8' options are
enabled by default, but can be disabled by explicitly setting them to 0, e.g.

  print $doc->json( pretty=>1, canonical=>1, utf8=>0 );

=item C<< $doc->model >>

Returns data as an RDF::Trine::Model, suitable for serialising as
RDF or running SPARQL queries.

=item C<< $object->serialise_model(as => $format) >> 

As C<model> but returns a string.

=item C<< $doc->add_to_model($model) >>

Adds data to an existing RDF::Trine::Model.

Returns a reference to the document.

=back

=head2 Utility Functions

=over 4

=item C<< HTML::Microformats->modules >>

Returns a list of Perl modules, each of which implements a specific
microformat.

=item C<< HTML::Microformats->formats >>

As per C<modules>, but strips 'HTML::Microformats::Format::' off the
module name, and sorts alphabetically.

=back

=head1 WHY ANOTHER MICROFORMATS MODULE?

There already exist two microformats packages on CPAN (see L<Text::Microformat>
and L<Data::Microformat>), so why create another?

Firstly, HTML::Microformats isn't being created from scratch. It's actually a
fork/clean-up of a non-CPAN application (Swignition), and in that sense
predates Text::Microformat (though not Data::Microformat).

It has a number of other features that distinguish it from the existing
packages:

=over 4

=item * It supports more formats.

HTML::Microformats supports hCard, hCalendar, rel-tag, geo, adr,
rel-enclosure, rel-license, hReview, hResume, hRecipe, xFolk, XFN,
hAtom, hNews and more.

=item * It supports more patterns.

HTML::Microformats supports the include pattern, abbr pattern, table cell
header pattern, value excerpting and other intricacies of microformat parsing
better than the other modules on CPAN.

=item * It offers RDF support.

One of the key features of HTML::Microformats is that it makes data
available as RDF::Trine models. This allows your application to benefit
from a rich, feature-laden Semantic Web toolkit. Data gleaned from
microformats can be stored in a triple store; output in RDF/XML or
Turtle; queried using the SPARQL or RDQL query languages; and more.

If you're not comfortable using RDF, HTML::Microformats also makes
all its data available as native Perl objects.

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::Documentation::Notes>.

Individual format modules:

=over 4

=item * L<HTML::Microformats::Format::adr>

=item * L<HTML::Microformats::Format::figure>

=item * L<HTML::Microformats::Format::geo>

=item * L<HTML::Microformats::Format::hAtom>

=item * L<HTML::Microformats::Format::hAudio>

=item * L<HTML::Microformats::Format::hCalendar>

=item * L<HTML::Microformats::Format::hCard>

=item * L<HTML::Microformats::Format::hListing>

=item * L<HTML::Microformats::Format::hMeasure>

=item * L<HTML::Microformats::Format::hNews>

=item * L<HTML::Microformats::Format::hProduct>

=item * L<HTML::Microformats::Format::hRecipe>

=item * L<HTML::Microformats::Format::hResume>

=item * L<HTML::Microformats::Format::hReview>

=item * L<HTML::Microformats::Format::hReviewAggregate>

=item * L<HTML::Microformats::Format::OpenURL_COinS>

=item * L<HTML::Microformats::Format::RelEnclosure>

=item * L<HTML::Microformats::Format::RelLicense>

=item * L<HTML::Microformats::Format::RelTag>

=item * L<HTML::Microformats::Format::species>

=item * L<HTML::Microformats::Format::VoteLinks>

=item * L<HTML::Microformats::Format::XFN>

=item * L<HTML::Microformats::Format::XMDP>

=item * L<HTML::Microformats::Format::XOXO>

=back

Similar modules:
L<RDF::RDFa::Parser>,
L<HTML::HTML5::Microdata::Parser>,
L<XML::Atom::Microformats>,
L<Text::Microformat>,
L<Data::Microformats>.

Related web sites:
L<http://microformats.org/>, L<http://www.perlrdf.org/>.

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

