package HTML::HTML5::Outline;

use 5.008;
use strict;

use Carp qw[];
use HTML::HTML5::Outline::Outlinee;
use HTML::HTML5::Outline::Section;
use HTML::HTML5::Parser;
use Scalar::Util qw[blessed];
use XML::LibXML;

our $VERSION = '0.006';

my $HAS_RDF = undef;

sub import
{
	my ($class, %import) = @_;
	if (exists $import{rdf} and !$import{rdf})
	{
		$HAS_RDF = 0;
	}
	else
	{
		local $@;
		$HAS_RDF = eval 'require HTML::HTML5::Outline::RDF; 1' || 0;
		Carp::croak("RDF support not available: $@\n")
			if (exists $import{rdf} and $import{rdf} and !$HAS_RDF);
	}
}

sub has_rdf
{
	return $HAS_RDF;
}

sub new
{
	my ($class, $dom, %options) = @_;

	$options{parser} = 'html' unless defined $options{parser};

	unless (blessed($dom) and $dom->isa('XML::LibXML::Document'))
	{
		my $parser = (lc $options{parser} eq 'xml' or lc $options{parser} eq 'xhtml')
			? XML::LibXML->new
			: HTML::HTML5::Parser->new;
		$dom = $parser->parse_string($dom);
	}

	my $self = bless {
		count            => 0,
		current_outlinee => undef,
		current_section  => undef,
		stack            => [],
		outlines         => {},
		page             => \%options,
		options          => \%options,
		dom              => $dom,
		element_subjects => $options{element_subjects},
	}, $class;
	
	my @roots = $dom->getElementsByTagName('html');
	my $root  = $roots[0];
	
	return unless $root;
	
	my $node = $root;
	my $r;
	START: while ($node)
	{
		$r = $self->tag('start', $node);
		if ($node->firstChild)
		{
			$node = $node->firstChild;
			next START;
		}
		while ($node)
		{
			$r = $self->tag('end', $node);
			last START if ($r<0);
			if ($node->nextSibling)
			{
				$node = $node->nextSibling;
				next START;
			}
			if ($node == $root)
				{ $node = undef; }
			else
				{ $node = $node->parentNode; }
		}
	}

	$self->{primary_outlinee} = k($self->{current_outlinee});
	$self->{primary_outline}  = $self->{outlines}->{$self->{primary_outlinee}};
	
	return $self;
}

sub primary_outlinee { return $_[0]->{primary_outline}; }

sub to_hashref
{
	my ($self) = @_;

	unless (defined $self->{hashref})
	{
		$self->{hashref} = $self->primary_outlinee->to_hashref;
	}
	
	return $self->{hashref};
}

sub _mk_outlinee
{
	my ($self, %options) = @_;
	$options{outliner} = $self;
	return HTML::HTML5::Outline::Outlinee->new(%options);
}

sub _mk_section
{
	my ($self, %options) = @_;
	$options{outliner} = $self;
	return HTML::HTML5::Outline::Section->new(%options);
}

sub tag
{
	my $self = shift;
	my $type = shift;  # 'start' or 'end'
	my $node = shift;
	
	my $top_of_stack;
	if ($self->{stack})
			{ $top_of_stack = $self->{stack}->[-1]; }
	
	# If the top of the stack is an element, and you are exiting that element
	if ($type eq 'end' && $top_of_stack && (k($top_of_stack) eq k($node)))
	{
		# Note: The element being exited is a heading content element.
		warn("This element should be a heading content element!\n")
			unless ( $self->is_heading_content($node) );
		
		# Pop that element from the stack.
		pop @{ $self->{stack} };
	}
	
	# If the top of the stack is a heading content element
	elsif ( $top_of_stack && $self->is_heading_content($top_of_stack) )
	{
		# Do nothing.
	}
	
	# When entering a sectioning content element or a sectioning root element
	elsif ($type eq 'start' && ($self->is_sectioning_content($node)||$self->is_sectioning_root($node)))
	{
		# XXX: If current outlinee is not null, and the current section has no heading, create an implied heading and let that be the heading for the current section.
		
		# If current outlinee is not null, push current outlinee onto the stack.
		push @{ $self->{stack} }, $self->{current_outlinee}
			if (defined $self->{current_outlinee});
		
		# Let current outlinee be the element that is being entered.
		$self->{current_outlinee} = $node;
		
		# Let current section be a newly created section for the current outlinee
		#     element.
		$self->{current_section} = $self->_mk_section(
			document_order => $self->{count}++,
			);
		
		# Let there be a new outline for the new current outlinee, initialized
		#     with just the new current section as the only section in the
		#     outline.
		$self->{outlines}->{ k($self->{current_outlinee}) } = $self->_mk_outlinee(
			document_order => $self->{count}++,
			sections => [$self->{current_section}],
			element  => $self->{current_outlinee},
			tagname  => $self->{current_outlinee}->tagName,
			);
	}
	
	# When exiting a sectioning content element, if the stack is not empty
	elsif ($type eq 'end' && $top_of_stack && $self->is_sectioning_content($node))
	{
		# Pop the top element from the stack, and let the current outlinee be
		#     that element.
		$self->{current_outlinee} = pop @{ $self->{stack} };
		
		# Let current section be the last section in the outline of the current
		#     outlinee element.
		my $ootco = $self->{outlines}->{ k($self->{current_outlinee}) };
		$self->{current_section} = $ootco->{sections}->[-1]
			if defined $ootco->{sections}->[-1];
			
		# Append the outline of the sectioning content element being exited to
		#     the current section. (This does not change which section is the
		#     last section in the outline.)
		push @{ $self->{current_section}->{outlines} },
			$self->{outlines}->{ k($node) };
	}
	
	# When exiting a sectioning root element, if the stack is not empty
	elsif ($type eq 'end' && $top_of_stack && $self->is_sectioning_root($node))
	{
		# Pop the top element from the stack, and let the current outlinee be
		#     that element.
		$self->{current_outlinee} = pop @{ $self->{stack} };
		
		# Let current section be the last section in the outline of the current
		#     outlinee element.
		$self->{current_section} =
			$self->{outlines}->{ k($self->{current_outlinee}) }->{sections}->[-1];
		
		# Finding the deepest child: If current section has no child sections,
		#    stop these steps.
		FINDING_DEEPEST_CHILD: while ($self->{current_section}->{sections}->[0])
		{
			# Let current section be the last child section of the current 'current
			#     section'.
			$self->{current_section} = $self->{current_section}->{sections}->[-1];
		}
	}

	# When exiting a sectioning content element or a sectioning root element	
	elsif ($type eq 'end' && ($self->is_sectioning_content($node)||$self->is_sectioning_root($node)))
	{
		# Note: The current outlinee is the element being exited.
		warn("The current outlinee seems to be wrong.\n")
			unless (k($self->{current_outlinee}) eq k($node));
			
		# Let current section be the first section in the outline of the current
		#     outlinee element.
		$self->{current_section} =
			$self->{outlines}->{ k($self->{current_outlinee}) }->{sections}->[0];
			
		# Skip to the next step in the overall set of steps. (The walk is over.)
		return -1;
	}
	
	# If the current outlinee is null.
	elsif (!defined $self->{current_outlinee})
	{
		# Do nothing.
	}
	
	# When entering a heading content element
	elsif ($type eq 'start' && $self->is_heading_content($node))
	{
		# If the current section has no heading, let the element being entered be
		#     the heading for the current section.
		if (!defined $self->{current_section}->{header})
		{
			$self->{current_section}->{header}  = $node;
			$self->{current_section}->{heading} = $self->stringify($node);
		}
			
		# Otherwise, if the element being entered has a rank equal to or greater
		#     than the heading of the last section of the outline of the current
		#     outlinee, then create a new section and append it to the outline of
		#     the current outlinee element, so that this new section is the new
		#     last section of that outline. Let current section be that new
		#     section. Let the element being entered be the new heading for the
		#     current section.
		elsif (rank_of($node) >= rank_of($self->{outlines}->{ k($self->{current_outlinee}) }->{sections}->[-1]->{header}))
		{
			$self->{current_section} = $self->_mk_section(
				document_order => $self->{count}++,
				header   => $node,
				heading  => $self->stringify($node),
				);
			push @{ $self->{outlines}->{ k($self->{current_outlinee}) }->{sections} },
				$self->{current_section};
		}

		# Otherwise, run these substeps:
		else
		{
			# Let candidate section be current section.
			my $candidate = $self->{current_section};
			
			while (1)
			{
				# If the element being entered has a rank lower than the rank of
				#     the heading of the candidate section, then create a new
				#     section, and append it to candidate section. (This does not
				#     change which section is the last section in the outline.)
				#     Let current section be this new section. Let the element
				#     being entered be the new heading for the current section.
				#     Abort these substeps.
				if (rank_of($node) < rank_of($candidate->{header}))
				{
					$self->{current_section} = $self->_mk_section(
						document_order => $self->{count}++,
						header   => $node,
						heading  => $self->stringify($node),
						parent   => $candidate,
						);
					push @{ $candidate->{sections} }, $self->{current_section};
					last;
				}
				
				# Let new candidate section be the section that contains candidate
				#     section in the outline of current outlinee.
				# Let candidate section be new candidate section.
				$candidate = $candidate->{parent};
			}
			
			# Push the element being entered onto the stack. (This causes the
			#     algorithm to skip any descendants of the element.)
			push @{ $self->{stack} }, $node;
		}
		
	}
	
	# Otherwise
	else
	{
		# Do nothing.
	}
	
	# In addition, whenever you exit a node, after doing the steps above, if
	#     current section is not null, associate the node with the section 
	#     current section.
	if ($type eq 'end' && $self->{current_section})
	{
		push @{ $self->{current_section}->{elements} }, $node;
	}
	
	return 1; # continue
}


sub is_sectioning_content
{
	my ($self, $node) = @_;	
	return 0 unless $node->nodeType == XML_ELEMENT_NODE;

	if ( $node->tagName =~ /^(section|nav|article|aside)$/i )
		{ return 1; }
		
	return 0;
}

sub is_sectioning_root
{
	my ($self, $node) = @_;	
	return 0 unless $node->nodeType == XML_ELEMENT_NODE;

	my @bodies = $self->{dom}->getElementsByTagName('body');
	
	if ( @bodies && $node->tagName =~ /^(blockquote|body|details|fieldset|figure|td|datagrid|th)$/i ) # <datagrid> from earlier HTML5 drafts; <th> I've added
		{ return 1; }

	# Some tagsoup parsers don't add in BODY elements when they're missing
	# from the markup, so if there is no <body> element found, treat <html>
	# as a sectioning root instead.
	elsif ( (!@bodies) && $node->tagName =~ /^(blockquote|html|details|fieldset|figure|td|datagrid|th)$/i )
		{ return 1; }

	# Support for figure microformat
	elsif ($node->hasAttribute('class') && $node->getAttribute('class') =~ /\bfigure\b/ && $self->{options}->{microformats})
		{ return 1; }
	
	# Support for XOXO
	elsif ($node->tagName =~ /^(ul|li)$/i && $node->hasAttribute('class') && $node->getAttribute('class') =~ /\bxoxo\b/ && $self->{options}->{microformats})
		{ return 1; }

	return 0;
}

sub is_heading_content
{
	my ($self, $node) = @_;	
	return 0 unless $node->nodeType == XML_ELEMENT_NODE;

	if ( $node->tagName =~ /^(h[1-6]|h|heading|hgroup)$/i )  # <h> from XHTML2; <heading> from early HTML5 drafts
		{ return 1; }
	# Perhaps add <caption>?
	return 0;
}

sub stringify
{
	my ($self, $node) = @_;
	return $node->textContent;
}

# Recall that h1 has the highest rank, and h6 has the lowest rank.
sub rank_of
{
	# not a method
	my $node = shift;
	return 0 unless ($node->nodeType==XML_ELEMENT_NODE);
	
	if ( $node->tagName =~ /^h([1-6])$/i )
		{ return 0 - $1; }
	if ( $node->tagName =~ /^h$/i )
		{ return 1; }
	if ( $node->tagName =~ /^(header|hgroup)$/i )
	{
		foreach my $c ($node->getElementsByTagName('*'))
			{ return rank_of($c) if (is_heading_content($c)); }
		return 1;
	}
	
	return 0;
}

sub k
{
	# not a method
	my $node = shift;
	return '/html/body' unless ($node);
	return $node->nodePath();
}

sub _node_lang
{
	my $self = shift;
	my $node = shift;

	my $XML_XHTML_NS = 'http://www.w3.org/1999/xhtml';

	if ($node->hasAttributeNS(XML_XML_NS, 'lang'))
	{
		return _valid_lang($node->getAttributeNS(XML_XML_NS, 'lang')) ?
			$node->getAttributeNS(XML_XML_NS, 'lang'):
			undef;
	}

	if ($node->hasAttributeNS($XML_XHTML_NS, 'lang'))
	{
		return _valid_lang($node->getAttributeNS($XML_XHTML_NS, 'lang')) ?
			$node->getAttributeNS($XML_XHTML_NS, 'lang'):
			undef;
	}

	if ($node->hasAttributeNS(undef, 'lang'))
	{
		return _valid_lang($node->getAttributeNS(undef, 'lang')) ?
			$node->getAttributeNS(undef, 'lang'):
			undef;
	}

	if ($node != $self->{'dom'}->documentElement
	&&  defined $node->parentNode
	&&  $node->parentNode->nodeType == XML_ELEMENT_NODE)
	{
		return $self->_node_lang($node->parentNode);
	}
	
	return $self->{'options'}->{'default_language'};
}

sub _valid_lang
{
	my $value_to_test = shift;

	return 1 if (defined $value_to_test) && ($value_to_test eq '');
	return 0 unless defined $value_to_test;
	
	# Regex for recognizing RFC 4646 well-formed tags
	# http://www.rfc-editor.org/rfc/rfc4646.txt
	# http://tools.ietf.org/html/draft-ietf-ltru-4646bis-21

	# The structure requires no forward references, so it reverses the order.
	# It uses Java/Perl syntax instead of the old ABNF
	# The uppercase comments are fragments copied from RFC 4646

	# Note: the tool requires that any real "=" or "#" or ";" in the regex be escaped.

	my $alpha      = '[a-z]';      # ALPHA
	my $digit      = '[0-9]';      # DIGIT
	my $alphanum   = '[a-z0-9]';   # ALPHA / DIGIT
	my $x          = 'x';          # private use singleton
	my $singleton  = '[a-wyz]';    # other singleton
	my $s          = '[_-]';       # separator -- lenient parsers will use [_-] -- strict will use [-]

	# Now do the components. The structure is slightly different to allow for capturing the right components.
	# The notation (?:....) is a non-capturing version of (...): so the "?:" can be deleted if someone doesn't care about capturing.

	my $language   = '([a-z]{2,8}) | ([a-z]{2,3} $s [a-z]{3})';
	
	# ABNF (2*3ALPHA) / 4ALPHA / 5*8ALPHA  --- note: because of how | works in regex, don't use $alpha{2,3} | $alpha{4,8} 
	# We don't have to have the general case of extlang, because there can be only one extlang (except for zh-min-nan).

	# Note: extlang invalid in Unicode language tags

	my $script = '[a-z]{4}' ;   # 4ALPHA 

	my $region = '(?: [a-z]{2}|[0-9]{3})' ;    # 2ALPHA / 3DIGIT

	my $variant    = '(?: [a-z0-9]{5,8} | [0-9] [a-z0-9]{3} )' ;  # 5*8alphanum / (DIGIT 3alphanum)

	my $extension  = '(?: [a-wyz] (?: [_-] [a-z0-9]{2,8} )+ )' ; # singleton 1*("-" (2*8alphanum))

	my $privateUse = '(?: x (?: [_-] [a-z0-9]{1,8} )+ )' ; # "x" 1*("-" (1*8alphanum))

	# Define certain grandfathered codes, since otherwise the regex is pretty useless.
	# Since these are limited, this is safe even later changes to the registry --
	# the only oddity is that it might change the type of the tag, and thus
	# the results from the capturing groups.
	# http://www.iana.org/assignments/language-subtag-registry
	# Note that these have to be compared case insensitively, requiring (?i) below.

	my $grandfathered  = '(?:
			  (en [_-] GB [_-] oed)
			| (i [_-] (?: ami | bnn | default | enochian | hak | klingon | lux | mingo | navajo | pwn | tao | tay | tsu ))
			| (no [_-] (?: bok | nyn ))
			| (sgn [_-] (?: BE [_-] (?: fr | nl) | CH [_-] de ))
			| (zh [_-] min [_-] nan)
			)';

	# old:         | zh $s (?: cmn (?: $s Hans | $s Hant )? | gan | min (?: $s nan)? | wuu | yue );
	# For well-formedness, we don't need the ones that would otherwise pass.
	# For validity, they need to be checked.

	# $grandfatheredWellFormed = (?:
	#         art $s lojban
	#     | cel $s gaulish
	#     | zh $s (?: guoyu | hakka | xiang )
	# );

	# Unicode locales: but we are shifting to a compatible form
	# $keyvalue = (?: $alphanum+ \= $alphanum+);
	# $keywords = ($keyvalue (?: \; $keyvalue)*);

	# We separate items that we want to capture as a single group

	my $variantList   = $variant . '(?:' . $s . $variant . ')*' ;     # special for multiples
	my $extensionList = $extension . '(?:' . $s . $extension . ')*' ; # special for multiples

	my $langtag = "
			($language)
			($s ( $script ) )?
			($s ( $region ) )?
			($s ( $variantList ) )?
			($s ( $extensionList ) )?
			($s ( $privateUse ) )?
			";

	# Here is the final breakdown, with capturing groups for each of these components
	# The variants, extensions, grandfathered, and private-use may have interior '-'
	
	my $r = ($value_to_test =~ 
		/^(
			($langtag)
		 | ($privateUse)
		 | ($grandfathered)
		 )$/xi);
	
	return $r;
}

1;

__END__

=head1 NAME

HTML::HTML5::Outline - implementation of the HTML5 Outline algorithm

=head1 SYNOPSIS

	use JSON;
	use HTML::HTML5::Outline;
	
	my $html = <<'HTML';
	<!doctype html>
	<h1>Hello</h1>
	<h2>World</h2>
	<h1>Good Morning</h1>
	<h2>Vietnam</h2>
	HTML
	
	my $outline = HTML::HTML5::Outline->new($html);
	print to_json($outline->to_hashref, {pretty=>1,canonical=>1});

=head1 DESCRIPTION

This is an implementation of the HTML5 Outline algorithm, as per
L<http://www.w3.org/TR/html5/sections.html#outlines>.

The module can output a JSON-friendly hashref, or an RDF model.

=head2 Constructor

=over

=item * C<< HTML::HTML5::Outline->new($html, %options) >>

Construct a new outline. C<< $html >> is the HTML to generate an outline from,
either as an HTML or XHTML string, or as an L<XML::LibXML::Document> object.

Options:

=over

=item * B<default_language> - default language to assume text is in when no
lang/xml:lang attribute is available. e.g. 'en-gb'.

=item * B<element_subjects> - rather advanced feature that doesn't bear
explaining. See USE WITH RDF::RDFA::PARSER for an example.

=item * B<microformats> - support C<< <ul class="xoxo"> >>,
C<< <ol class="xoxo"> >> and C<< <whatever class="figure"> >> as
sectioning elements (like C<< <section> >>, C<< <figure> >>, etc).
Boolean, defaults to false.

=item * B<parser> - 'html' (default) or 'xml' - choose the parser to use for
XHTML/HTML. If the constructor is passed an XML::LibXML::Document, this is
ignored.

=item * B<suppress_collections> - allows rdf:List stuff to be suppressed
from RDF output. RDF output - especially in Turtle format - looks somewhat
nicer without them, but if you care about the order of headings and sections,
then you'll want them. Boolean, defaults to false.

=item * B<uri> - the document URI for resolving relative URI references.
Only really used by the RDF output.

=back

=back

=head2 Object Methods

=over

=item * C<< to_hashref >>

Returns data as a nested hashref/arrayref structure. Dump it as JSON and
you'll figure out the format pretty easily.

=item * C<< to_rdf >>

Returns data as a n L<RDF::Trine::Model>. Requires RDF::Trine to be
installed. Otherwise this method won't exist.

=item * C<< primary_outlinee >>

Returns a L<HTML::HTML5::Outline::Outlinee> element representing the
outline for the page.

=back

=head2 Class Methods

=over

=item * C<< has_rdf >>

Indicates whether the C<< to_rdf >> object method exists.

=back


=head1 USE WITH RDF::RDFA::PARSER

This module produces RDF data where many of the resources described
are HTML elements. RDFa data typically does not, but RDF::RDFa::Parser
does also support some extensions to RDFa which do (e.g. support for the
C<cite> and C<role> attributes). It's useful to combine the RDF data
from each, and RDF::RDFa::Parser 1.093 and upwards contains a few shims
to make this possible.

Without further ado...

	use HTML::HTML5::Outline;
	use RDF::RDFa::Parser 1.093;
	use RDF::TrineShortcuts;

	my $rdfa = RDF::RDFa::Parser->new(
		$html_source,
		$base_url,
		RDF::RDFa::Parser::Config->new(
			'html5', '1.1',
			role_attr     => 1,
			cite_attr     => 1,
			longdesc_attr => 1,
			),
		)->consume;
	
	my $outline = HTML::HTML5::Outline->new(
		$rdfa->dom,
		uri              => $rdfa->uri,
		element_subjects => $rdfa->element_subjects,
		);
	
	# Merging two graphs is pretty complicated in RDF::Trine
	# but a little easier with RDF::TrineShortcuts...
	my $combined = rdf_parse();
	rdf_parse($rdfa->graph,     model => $combined);
	rdf_parse($outline->to_rdf, model => $combined);
	
	my $NS = {
		dc    => 'http://purl.org/dc/terms/',
		o     => 'http://ontologi.es/outline#',
		type  => 'http://purl.org/dc/dcmitype/',
		xs    => 'http://www.w3.org/2001/XMLSchema#',
		xhv   => 'http://www.w3.org/1999/xhtml/vocab#',
		};
	
	print rdf_string($combined => 'Turtle', namespaces => $NS);

=head1 SEE ALSO

L<HTML::HTML5::Outline::RDF>,
L<HTML::HTML5::Outline::Outlinee>,
L<HTML::HTML5::Outline::Section>.

L<HTML::HTML5::Parser>, L<HTML::HTML5::Sanity>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

This module is a fork of the document structure parser from Swignition
<http://buzzword.org.uk/swignition/>.

That in turn includes the following credits: thanks to Ryan King and
Geoffrey Sneddon for pointing me towards [the HTML5] algorithm. I also
used Geoffrey's python implementation as a crib sheet to help me figure
out what was supposed to happen when the HTML5 spec was ambiguous.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2008-2011 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
