package HTML::HTML5::Microdata::Parser;

=head1 NAME

HTML::HTML5::Microdata::Parser - fairly experimental parser for HTML 'microdata'

=head1 SYNOPSIS

  use HTML::HTML5::Microdata::Parser;
  
  my $parser = HTML::HTML5::Microdata::Parser->new($html, $baseURI);
  my $graph  = $parser->graph;

=cut

use 5.010;
use strict;
use utf8;

use constant XML_XHTML_NS => 'http://www.w3.org/1999/xhtml';

use Encode 0 qw(encode_utf8);
use HTML::HTML5::Microdata::Strategy::Basic;
use HTML::HTML5::Microdata::Strategy::Heuristic;
use HTML::HTML5::Microdata::Strategy::Microdata0;
use HTML::HTML5::Parser 0.107;
use HTML::HTML5::Sanity 0.102;
use RDF::Trine 0.135;
use Scalar::Util 0 qw(blessed);
use URI::Escape 0;
use URI::URL 0;
use XML::LibXML 1.70 qw(:all);

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.100';

=head1 DESCRIPTION

This package aims to have a roughly compatible API to RDF::RDFa::Parser.

Microdata is an experimental metadata format, not in wide use. Use this module
at your own risk.

=over 8

=item $p = HTML::HTML5::Microdata::Parser->new($html, $baseuri, \%options, $storage)

This method creates a new HTML::HTML5::Microdata::Parser object and returns it.

The $xhtml variable may contain an XHTML/XML string, or a
XML::LibXML::Document. If a string, the document is parsed using
HTML::HTML5::Parser and HTML::HTML5::Sanity, which may throw an
exception. HTML::HTML5::Microdata::Parser does not catch the exception.

The base URI is used to resolve relative URIs found in the document.

Options [default in brackets]:

  * alt_stylesheet  - Magic rel="alternate stylesheet". [1]
  * auto_config     - See section "Auto Config" [0]
  * mhe_lang        - Process <meta http-equiv=Content-Language>.
                      [1]
  * prefix_empty    - URI prefix for itemprops of untyped items.
                      [undef]
  * strategy        - URI generation strategy for itemprops of
                      typed items. [HTML::HTML5::Microdata::
                      Strategy::Heuristic]
  * tdb_service     - thing-described-by.org when possible. [0] 
  * xhtml_base      - Process <base href> element. [1]
  * xhtml_lang      - Process @lang. [1]
  * xhtml_meta      - Process <meta>. [0]
  * xhtml_cite      - Process @cite. [0]
  * xhtml_rel       - Process @rel. [0]
  * xhtml_time      - Process <time> element more nicely. [0]
  * xhtml_title     - Process <title> element. [0]
  * xml_lang        - Process @xml:lang. [1]

$storage is an RDF::Trine::Storage object. If undef, then a new
temporary store is created.

=cut

sub new
{
	my $class   = shift;
	my $xhtml   = shift;
	my $baseuri = shift;
	my $options = shift;
	my $store   = shift;
	my $DOMTree;

	if (blessed($xhtml) and $xhtml->isa('XML::LibXML::Document'))
	{
		$DOMTree = $xhtml;
		$xhtml = $DOMTree->toString;
	}
	else
	{
		my $parser  = HTML::HTML5::Parser->new;
		local $HTML::HTML5::Sanity::FIX_LANG_ATTRIBUTES = 2;
		$DOMTree = fix_document($parser->parse_string($xhtml));
	}
	
	$store = RDF::Trine::Store::DBI->temporary_store
		unless defined $store;

	my $self = {
			'xhtml'   => $xhtml,
			'baseuri' => $baseuri,
			'origbase' => $baseuri,
			'DOM'     => $DOMTree,
			'RESULTS' => RDF::Trine::Model->new($store),
			'bnodes'  => 0,
			'sub'     => {},
			'consumed'=> 0,
			'options' => {
				'alt_stylesheet'  => 1,
				'auto_config'     => 0,
				'mhe_lang'        => 1,
				'prefix_empty'    => undef,
				'strategy'        => 'HTML::HTML5::Microdata::Strategy::Heuristic',
				'tdb_service'     => 0,
				'xhtml_base'      => 1,
				'xhtml_cite'      => 0,
				'xhtml_lang'      => 1,
				'xhtml_meta'      => 0,
				'xhtml_rel'       => 0,
				'xhtml_time'      => 0,
				'xhtml_title'     => 0,
				'xml_lang'        => 1,
				},
			'default_language' => undef,
		};
	bless $self, $class;
	
	foreach my $o (keys %$options)
	{
		$self->{options}{$o} = $options->{$o};
	}
	
	$self->_auto_config;
	
	# HTML <base> element.
	if ($self->{options}{xhtml_base})
	{
		my @bases = $self->{DOM}->getElementsByTagName('base');
		my $base;
		foreach my $b (@bases)
		{
			if ($b->hasAttribute('href'))
			{
				$base = $b->getAttribute('href');
				$base =~ s/#.*$//g;
			}
		}
		$self->{baseuri} = $self->uri($base)
			if (defined $base and length $base);
	}
	
	if ($self->{options}{mhe_lang})
	{
		my $xpc = XML::LibXML::XPathContext->new;
		$xpc->registerNs(x => XML_XHTML_NS);
		my $nodes = $xpc->find('//x:meta[translate(@http-equiv,"CONTENT-LANGUAGE","content-language"="content-language")]/@content', $self->{'DOM'}->documentElement);
		foreach my $node ($nodes->get_nodelist)
		{
			if ($node->getValue =~ /^\s*([^\s,]+)/)
			{
				my $lang = $1;
				if (_valid_lang($lang))
				{
					$self->{default_language} = $lang;
					last;
				}
			}
		}
	}
		
	return $self;
}

=item $p->xhtml

Returns the HTML source of the document being parsed.

=cut

sub xhtml
{
	my $self = shift;
	return $self->{xhtml};
}

=item $p->uri

Returns the base URI of the document being parsed. This will usually be the
same as the base URI provided to the constructor, but may differ if the
document contains a <base> HTML element.

Optionally it may be passed a parameter - an absolute or relative URI - in
which case it returns the same URI which it was passed as a parameter, but
as an absolute URI, resolved relative to the document's base URI.

This seems like two unrelated functions, but if you consider the consequence
of passing a relative URI consisting of a zero-length string, it in fact makes
sense.

=cut

sub uri
{
	my $self  = shift;
	my $param = shift // '';
	my $opts  = shift // {};
	
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
	
	my $base = $self->{baseuri};
	if ($self->{options}{xml_base})
	{
		$base = $opts->{xml_base} || $self->{baseuri};
	}
	
	my $url = url $param, $base;
	my $rv  = $url->abs->as_string;

	while ($rv =~ m!^(http://.*)(\.\./|\.)+(\.\.|\.)?$!i)
	{
		$rv = $1;
	}
	
	return $rv;
}

=item $p->dom

Returns the parsed XML::LibXML::Document.

=cut

sub dom
{
	my $self = shift;
	return $self->{DOM};
}

=item $p->set_callbacks(\%callbacks)

Set callback functions for the parser to call on certain events. These are only necessary if
you want to do something especially unusual.

  $p->set_callbacks({
    'pretriple_resource' => sub { ... } ,
    'pretriple_literal'  => sub { ... } ,
    'ontriple'           => undef ,
    });

Either of the two pretriple callbacks can be set to the string 'print' instead of a coderef.
This enables built-in callbacks for printing Turtle to STDOUT.

For details of the callback functions, see the section CALLBACKS. C<set_callbacks> must
be used I<before> C<consume>. C<set_callbacks> itself returns a reference to the parser
object itself.

=cut

sub set_callbacks
{
	my $self = shift;

	if ('HASH' eq ref $_[0])
	{
		$self->{sub} = $_[0];
		$self->{sub}{pretriple_resource} = \&_print0
			if lc $self->{sub}{pretriple_resource} eq 'print';
		$self->{sub}{pretriple_literal} = \&_print1
			if lc $self->{sub}{pretriple_literal} eq 'print';
	}
	elsif (defined $_[0])
	{
		die("What kind of callback hashref was that??\n");
	}
	else
	{
		$self->{sub} = undef;
	}
	
	return $self;
}

sub _print0
# Prints a Turtle triple.
{
	my $self    = shift;
	my $element = shift;
	my $subject = shift;
	my $pred    = shift;
	my $object  = shift;
	my $graph   = shift;
	
	if ($graph)
	{
		print "# GRAPH $graph\n";
	}
	if ($element)
	{
		printf("# Triple on element %s.\n", $element->nodePath);
	}
	else
	{
		printf("# Triple.\n");
	}

	printf("%s %s %s .\n",
		($subject =~ /^_:/ ? $subject : "<$subject>"),
		"<$pred>",
		($object =~ /^_:/ ? $object : "<$object>"));
	
	return undef;
}

sub _print1
# Prints a Turtle triple.
{
	my $self    = shift;
	my $element = shift;
	my $subject = shift;
	my $pred    = shift;
	my $object  = shift;
	my $dt      = shift;
	my $lang    = shift;
	my $graph   = shift;
	
	# Clumsy, but probably works.
	$object =~ s/\\/\\\\/g;
	$object =~ s/\n/\\n/g;
	$object =~ s/\r/\\r/g;
	$object =~ s/\t/\\t/g;
	$object =~ s/\"/\\\"/g;
	
	if ($graph)
	{
		print "# GRAPH $graph\n";
	}
	if ($element)
	{
		printf("# Triple on element %s.\n", $element->nodePath);
	}
	else
	{
		printf("# Triple.\n");
	}

	no warnings;
	printf("%s %s %s%s%s .\n",
		($subject =~ /^_:/ ? $subject : "<$subject>"),
		"<$pred>",
		"\"$object\"",
		(length $dt ? "^^<$dt>" : ''),
		((length $lang and !length $dt) ? "\@$lang" : '')
		);
	use warnings;
	
	return undef;
}

=item $p->consume

The document is parsed for Microdata. Nothing of interest is returned by this
function, but the triples extracted from the document are passed to the
callbacks as each one is found.

The C<graph> method automatically calls C<consume>, so normally you don't need
to call it manually. If you're using callback functions, it may be useful though.

=cut

sub consume
{
	my $self = shift;
	
	return $self if $self->{consumed};
	
	my $xpc = XML::LibXML::XPathContext->new;
	$xpc->registerNs(x => XML_XHTML_NS);
	
	if ($self->{options}{xhtml_title})
	{
		my $titles = $xpc->find(
			'//x:title', $self->{'DOM'}->documentElement);
			
		# If the title element is not null, then generate the following triple:
		foreach my $title ($titles->get_nodelist)
		{
			$self->_rdf_triple_literal(
				$title,
				$self->{baseuri},                 # subject : the document's current address 
				'http://purl.org/dc/terms/title', # predicate : http://purl.org/dc/terms/title 
				$self->_stringify($title),        # object : the concatenation of the data of all the child text nodes of the title element, in tree order, 
				undef,                            # ... as a plain literal
				$self->_get_node_lang($title));   # ... with the language information set from the language of the title element, if it is not unknown. 
		}
	}
	
	if ($self->{options}{xhtml_rel})
	{
		# For each a, area, and link element in the Document, run these substeps:
		my @links = $xpc
			->find('//x:a[@rel][@href]', $self->{'DOM'}->documentElement)
			->get_nodelist;
		push @links, $xpc
			->find('//x:area[@rel][@href]', $self->{'DOM'}->documentElement)
			->get_nodelist;
		push @links, $xpc
			->find('//x:link[@rel][@href]', $self->{'DOM'}->documentElement)
			->get_nodelist;
		# If the element does not have a rel attribute, then skip this element.
		# If the element does not have an href attribute, then skip this element.
		
		foreach my $link (@links)
		{
			# If resolving the element's href attribute relative to the element is not successful, then skip this element.
			my $href = $self->uri( $link->getAttribute('href') );
			next unless defined $href;
			
			# Otherwise, split the value of the element's rel attribute on spaces, obtaining list of tokens.
			# <del>Convert each token in list of tokens to ASCII lowercase.</del>
			# <ins>Convert each token in list of tokens that does not contain a U+003A COLON characters (:) to ASCII lowercase.</ins>
			# <!-- http://www.w3.org/Bugs/Public/show_bug.cgi?id=8450 -->
			my $rels = $link->getAttribute('rel');
			$rels =~ s/\s+/ /g;
			$rels =~ s/(^\s+|\s+$)//g;
			my @raw_rels = split / /, $rels;
			my @rels;
			foreach my $r (@raw_rels)
			{
				push @rels, ( ($r=~/:/) ? $r : lc $r );
			}
			
			# If list of tokens contains more than one instance of the token up, then remove all such tokens.
			my $count_up = grep /^up$/, @rels;
			if ($count_up > 1)
			{
				@rels = grep !/^up$/, @rels;
			}
			
			# Coalesce duplicate tokens in list of tokens.
			@rels = keys %{{map { $_, 1 } @rels}};
			
			# If list of tokens contains both the tokens alternate and stylesheet, then remove them both and replace them with the single (uppercase) token ALTERNATE-STYLESHEET.
			if (($self->{options}{alt_stylesheet})
			and (grep /^alternate$/, @rels)
			and (grep /^stylesheet$/, @rels))
			{
				@rels = grep !/^(alternate|stylesheet)$/, @rels;
				push @rels, 'ALTERNATE-STYLESHEET';
			}
			
			foreach my $token (@rels)
			{
				# For each token token in list of tokens that contains no U+003A COLON characters (:), generate the following triple:
				if ($token !~ /:/)
				{
					$self->_rdf_triple(
						$link,
						$self->{baseuri},    # subject : the document's current address 
						'http://www.w3.org/1999/xhtml/vocab#'.uri_escape($token), # predicate : the concatenation of the string "http://www.w3.org/1999/xhtml/vocab#" and token, with any characters in token that are not valid in the <ifragment> production of the IRI syntax being %-escaped [RFC3987] 
						$href);              # object : the absolute URL that results from resolving the value of the element's href attribute relative to the element 
				}
				else
				{
					# For each token token in list of tokens that is an absolute URL, generate the following triple:
					my $predicate = $self->uri($token, {'require-absolute'=>1});
					if (defined $predicate)
					{
						$self->_rdf_triple(
							$link,
							$self->{baseuri},   # subject : the document's current address 
							$token,             # predicate : token
							$href);             # object : the absolute URL that results from resolving the value of the element's href attribute relative to the element 
					}
				}
			}
		}
	}
	
	if ($self->{options}{xhtml_meta})
	{
		# For each meta element in the Document that has a name attribute and a content attribute,
		my @metas = $xpc
			->find('//x:meta[@name][@content]', $self->{'DOM'}->documentElement)
			->get_nodelist;

		foreach my $meta (@metas)
		{
			my $token = $meta->getAttribute('name');
			
			# if the value of the name attribute contains no U+003A COLON characters (:), generate the following triple:
			if ($token !~ /:/)
			{
				$self->_rdf_triple_literal(
					$meta,
					$self->{baseuri},                # subject : the document's current address 
					'http://www.w3.org/1999/xhtml/vocab#'.uri_escape(lc $token), # predicate : the concatenation of the string "http://www.w3.org/1999/xhtml/vocab#" and token, with any characters in token that are not valid in the <ifragment> production of the IRI syntax being %-escaped [RFC3987] 
					$meta->getAttribute('content'),  # object : the value of the element's content attribute, 
					undef,                           # as a plain literal, 
					$self->_get_node_lang($meta));   # with the language information set from the language of the element, if it is not unknown
			}
			else
			{
				# For each token token in list of tokens that is an absolute URL, generate the following triple:
				my $predicate = $self->uri($token, {'require-absolute'=>1});
				if (defined $predicate)
				{
					$self->_rdf_triple_literal(
						$meta,
						$self->{baseuri},               # subject : the document's current address 
						$token,                         # predicate : token
						$meta->getAttribute('content'), # object : the value of the element's content attribute, 
						undef,                          # as a plain literal, 
						$self->_get_node_lang($meta));  # with the language information set from the language of the element, if it is not unknown
				}
			}		
		}
	}
	
	if ($self->{options}{xhtml_cite})
	{
		# For each blockquote and q element in the Document that has a cite attribute 
		my @quotes = $xpc
			->find('//x:blockquote[@cite]', $self->{'DOM'}->documentElement)
			->get_nodelist;
		push @quotes, $xpc
			->find('//x:q[@cite]', $self->{'DOM'}->documentElement)
			->get_nodelist;
			
		foreach my $quote (@quotes)
		{
			# that resolves successfully relative to the element, 
			my $cite = $self->uri($quote->getAttribute('cite'));
			
			if (defined $cite)
			{
				# generate the following triple:
				$self->_rdf_triple(
					$quote,
					$self->{baseuri},                  # subject : the document's current address 
					'http://purl.org/dc/terms/source', # predicate : http://purl.org/dc/terms/source 
					$cite);                            # object : the absolute URL that results from resolving the value of the element's cite attribute relative to the element 
			}
		}
	}
	
	# For each element that is also a top-level microdata item, run the following steps:
	my @items = $xpc
		->find('//*[@itemscope]', $self->{'DOM'}->documentElement)
		->get_nodelist;
	
	foreach my $item (@items)
	{
		next if $item->hasAttribute('itemprop'); #[skip non-top-level]
		
		# Generate the triples for the item. Let [item address] be the subject returned.
		my $item_address = $self->consume_microdata_item($item);
		
		# Generate the following triple:
		$self->_rdf_triple(
			$item,
			$self->{baseuri},                               # subject : the document's current address 
			'http://www.w3.org/1999/xhtml/microdata#item',  # predicate : http://www.w3.org/1999/xhtml/microdata#item  
			$item_address);                                 # object : [item address]
	}
	
	$self->{consumed}++;
	
	return $self;
}

=item $p->consume_microdata_item($element)

You almost certainly do not want to use this method.

It will consume a single Microdata item, assuming that $element is an
element that does or should have the @itemscope attribute set. Returns
the URI or blank node identifier for the item.

This method is exposed mostly for the benefit of
L<HTML::HTML5::Microdata::ToRDFa>.

=cut

sub consume_microdata_item
{
	# When the user agent is to generate the triples for an item item, it must follow the following steps:
	my $self = shift;
	my $item = shift;
	
	# If item has a global identifier and that global identifier is an absolute URL, let [item address] be that global identifier. 
	my $item_address;
	if ($item->hasAttribute('itemid'))
	{
		$item_address = $self->uri($item->getAttribute('itemid'));
	}
	# Otherwise, let subject be a new blank node.
	else
	{
		$item_address = $self->_bnode($item);
	}
	
	# If item has an item type and that item type is an absolute URL, let [item type] be that item type.
	# Otherwise, let [item type] be the empty string.
	my $item_type = '';
	if ($item->hasAttribute('itemtype'))
	{
		$item_type = $self->uri($item->getAttribute('itemtype'), {'require-absolute'=>1}) // '';
	}

	# If [item type] is not the empty string, generate the following triple:
	if (length $item_type)
	{
		$self->_rdf_triple(
			$item,
			$item_address,                                      # subject : [item address]
			'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',  # predicate : http://www.w3.org/1999/02/22-rdf-syntax-ns#type  
			$item_type);                                        # object : [item type]
	}
	
	my @properties;
	# To find the properties of an item, the user agent must run the following steps:
	{
		my $xpc = XML::LibXML::XPathContext->new;
		$xpc->registerNs(x => XML_XHTML_NS);
	
		# Let root be the element with the itemscope attribute.
		my $root = $item;
		
		# Let pending be a stack of elements initially containing the child elements of
		# root, if any, in tree order (so that the first child element of root will be 
		# the first one to be popped from the stack). This list will be the one that holds
		# the elements that still need to be crawled.
		my @pending = $item->getChildrenByTagName('*');
		
		# Let properties be an empty list of elements. This list will be the result of
		# the algorithm: a list of elements with properties that apply to root.
		@properties = ();
		
		# If root has an itemref attribute, split the value of that itemref attribute on
		# spaces. For each resulting token, ID, if there is an element in the document
		# with the ID ID, then push the first such element onto pending.
		if ($root->hasAttribute('itemref'))
		{
			my @IDs = split /\s+/, $root->getAttribute('itemref');
			foreach my $ID (@IDs)
			{
				my $id_elems = $xpc->find("//*[\@id=\"$ID\"]", $item->ownerDocument->documentElement);
				
				if ($id_elems->get_nodelist)
				{
					my $first = shift @{[ $id_elems->get_nodelist ]};
					push @pending, $first;
				}
				else
				{
					warn "itemref references missing ID '$ID'\n";
				}
			}
		}

		my %removals;
		
		# For each element candidate in pending, run the following substeps:
		for (my $i=0; $i <= $#pending; $i++)
		{
			my $candidate = $pending[$i];
			
			next
				if $removals{$i};
			
			# Let scope be candidate's nearest ancestor element with an itemscope attribute specified.
			my $scope;
			my @ancestorsForLater;
			if ($candidate->parentNode)
			{
				$scope = $candidate->parentNode;
				while (defined $scope and $scope->nodeType == XML_ELEMENT_NODE)
				{
					push @ancestorsForLater, $scope;
					last if $scope->hasAttribute('itemscope');
					$scope = $scope->parentNode;
				}
			}
			
			# If one of the other elements in pending is also candidate, then
			# remove candidate from pending (i.e. remove duplicates).
			for (my $j=0; $j <= $#pending; $j++)
			{
				next if $i==$j;
				my $other_element = $pending[$j];
				
				if ($candidate == $other_element)
				{
					$removals{$i} = 1;
				}
			}

			# Otherwise, if one of the other elements in pending is an ancestor
			# element of candidate, and that element is scope, then remove
			# candidate from pending.
			if (defined $scope)
			{
				for (my $j=0; $j <= $#pending; $j++)
				{
					next if $i==$j;
					my $other_element = $pending[$j];
					
					if ($scope == $other_element)
					{
						$removals{$i} = 1;
					}
				}
			}
			
			# Otherwise, if one of the other elements in pending is an ancestor
			# element of candidate, and that element also has scope as its nearest
			# ancestor element with an itemscope attribute specified, then remove
			# candidate from pending.
			if (defined $scope)
			{
				for (my $j=0; $j <= $#pending; $j++)
				{
					next if $i==$j;
					my $other_element = $pending[$j];
					
					foreach my $ancestor (@ancestorsForLater)
					{
						if ($ancestor == $other_element)
						{
							$removals{$i} = 1;
						}
					}
				}
			}
		}

		my @newPending;
		for (my $i=0; $i <= $#pending; $i++)
		{
			push @newPending, $pending[$i] unless $removals{$i};
		}
		
		# Sort pending in tree order. #TOBY: I think this should work.
		@pending = sort { $a->nodePath cmp $b->nodePath } @newPending;
		
		# Loop: Pop the top element from pending and let current be that element.
		while (@pending)
		{
			my $current = shift @pending;
			
			# If current has an itemprop attribute, then append current to properties.
			if ($current->hasAttribute('itemprop'))
			{
				push @properties, $current;
			}
			
			# If current does not have an itemscope attribute, and current is an
			# element with child elements, then: push all the child elements of
			# current onto pending, in tree order (so the first child of current
			# will be the next element to be popped from pending).
			unless ($current->hasAttribute('itemscope'))
			{
				my @child_elements = $current->getChildrenByTagName('*');
				@pending = (@child_elements, @pending);
			}
			
			# End of loop: If pending is not empty, return to the step marked loop.
			last unless @pending;
		}
	}
	
	# For each element element that has one or more property names and is one of
	# the properties of the item item, in the order those elements are given by the
	# algorithm that returns the properties of an item, run the following substeps:
	foreach my $element (@properties)
	{
		# Let value be the property value of element.
		my $value;
		my $value_type;
		my $value_datatype;
		my $value_lang;
		
		# The property value of a name-value pair added by an element with an
		# itemprop attribute depends on the element, as follows:
		
		# If the element also has an itemscope attribute
		if ($element->hasAttribute('itemscope') and $element != $item)
		{
			# The value is the item created by the element.
			$value = $self->consume_microdata_item($element);
			$value_type = ((substr $value,0,2) eq '_:') ? 'bnode' : 'uri';
		}
		# If the element is a meta element
		elsif ($element->localname eq 'meta')
		{
			# The value is the value of the element's content attribute, if any, or
			# the empty string if there is no such attribute.
			$value = $element->getAttribute('content') // '';
			$value_type = 'literal';
			$value_lang = $self->_get_node_lang($element);
		}
		
		# If the element is an audio, embed, iframe, img, source, or video element
		elsif ($element->localname =~ /^(audio | embed | iframe | img | source | video)$/ix)
		{
			# The value is the absolute URL that results from resolving the value of the
			# element's src attribute relative to the element at the time the attribute is set
			if ($element->hasAttribute('src'))
			{
				$value = $self->uri($element->getAttribute('src'));
				$value_type = 'uri';
			}
			# or the empty string if there is no such attribute or if resolving it results in an error.
			else
			{
				warn "Property element requires \@src, but no such attribute found.\n";
				$value = '';
				$value_type = 'literal';
			}
		}
		# If the element is an a, area, or link element
		elsif ($element->localname =~ /^(a | area | link)$/ix)
		{
			# The value is the absolute URL that results from resolving the value of the
			# element's href attribute relative to the element at the time the attribute is set
			if ($element->hasAttribute('href'))
			{
				$value = $self->uri($element->getAttribute('href'));
				$value_type = 'uri';
			}
			# or the empty string if there is no such attribute or if resolving it results in an error.
			else
			{
				warn "Property element requires \@href, but no such attribute found.\n";
				$value = '';
				$value_type = 'literal';
			}
		}
		# If the element is an object element
		elsif ($element->localname =~ /^(object)$/ix)
		{
			# The value is the absolute URL that results from resolving the value of the element's
			# data attribute relative to the element at the time the attribute is set,
			if ($element->hasAttribute('data'))
			{
				$value = $self->uri($element->getAttribute('data'));
				$value_type = 'uri';
			}
			# or the empty string if there is no such attribute or if resolving it results in an error.
			else
			{
				warn "Property element requires \@data, but no such attribute found.\n";
				$value = '';
				$value_type = 'literal';
			}
		}
		# If the element is a time element with a datetime attribute
		elsif ($element->localname eq 'time')
		{
			# The value is the value of the element's datetime attribute.
			$value = $element->hasAttribute('datetime')
				? $element->getAttribute('datetime')
				: $self->_stringify($element);
			$value_type = 'literal';
			$value_lang = $self->_get_node_lang($element);
			
			if ($self->{options}{xhtml_time})
			{
				if ($value =~ /^(\-?\d{4,})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(:(\d{2})(?:\.\d+)?)?(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
				{
					$value_datatype  = 'http://www.w3.org/2001/XMLSchema#dateTime'
				}
				elsif ($value =~ /^(\d{2}):(\d{2})(:(\d{2})(?:\.\d+)?)?(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
				{
					$value_datatype  = 'http://www.w3.org/2001/XMLSchema#time'
				}
				elsif ($value =~ /^(\-?\d{4,})-(\d{2})-(\d{2})(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
				{
					$value_datatype  = 'http://www.w3.org/2001/XMLSchema#date'
				}
				elsif ($value =~ /^(\-?\d{4,})-(\d{2})(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
				{
					$value_datatype  = 'http://www.w3.org/2001/XMLSchema#gYearMonth'
				}
				elsif ($value =~ /^(\-?\d{4,})(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
				{
					$value_datatype  = 'http://www.w3.org/2001/XMLSchema#gYear'
				}
				elsif ($value =~ /^--(\d{2})-(\d{2})(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
				{
					$value_datatype  = 'http://www.w3.org/2001/XMLSchema#gMonthDay'
				}
				elsif ($value =~ /^---(\d{2})(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
				{
					$value_datatype  = 'http://www.w3.org/2001/XMLSchema#gDay'
				}
				elsif ($value =~ /^--(\d{2})(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
				{
					$value_datatype  = 'http://www.w3.org/2001/XMLSchema#gMonth'
				}
				
				if (defined $value_datatype)
				{
					$value           = uc $value;
					$value_lang      = undef;
				}
			}
		}
		# Otherwise
		else
		{
			# The value is the element's textContent.
			$value = $self->_stringify($element);
			$value_type = 'literal';
			$value_lang = $self->_get_node_lang($element); 
		}
		
		# The property names of an element are the tokens that the element's
		# itemprop attribute is found to contain when its value is split on 
		# spaces, with the order preserved but with duplicates removed (leaving
		# only the first occurrence of each name).
		my $property_names = $element->getAttribute('itemprop');
		$property_names =~ s/\s+/ /g;
		$property_names =~ s/(^\s+|\s+$)//g;
		my @property_names = split / /, $property_names;
		@property_names = keys %{{map { $_, 1 } @property_names}};
		
		# For each name name in element's property names, run the appropriate
		# substeps from the following list:
		foreach my $name (@property_names)
		{
			my $function = do
				{
					my $strategy = $self->{options}{strategy}
						// 'HTML::HTML5::Microdata::Strategy::Heuristic';
					
					if (ref $strategy eq 'CODE')
						{ $strategy }
					elsif (blessed($strategy) and $strategy->can('generate_uri'))
						{ sub { return $strategy->generate_uri(@_) } }
					elsif (length "$strategy")
						{ my $class = $strategy; sub { return $class->new->generate_uri(@_) } }
					else
						{ sub { return undef } }
				};
			
			my $predicate = $function->(
				name    => $name,
				type    => $item_type,
				element => $element,
				item    => $item,
				prefix_empty => $self->{options}{prefix_empty},
				);
			
			if (defined $predicate)
			{
				# Generate the following triple:
				# subject : [item address] 
				# object : value 
				if ($value_type eq 'literal')
				{
					$self->_rdf_triple_literal(
						$element,
						$item_address,
						$predicate,
						$value,
						$value_datatype,
						$value_lang);
				}
				else
				{
					$self->_rdf_triple(
						$element,
						$item_address,
						$predicate,
						$value);
				}
			}
		}
	}

	# Return [item address].
	return $item_address;
}

sub _get_node_lang
{
	my $self = shift;
	my $node = shift;

	if ($self->{options}{xml_lang}
	and $node->hasAttributeNS(XML_XML_NS, 'lang'))
	{
		return _valid_lang($node->getAttributeNS(XML_XML_NS, 'lang')) ?
			$node->getAttributeNS(XML_XML_NS, 'lang'):
			undef;
	}

	if ($self->{options}{xhtml_lang}
	and $node->hasAttributeNS(XML_XHTML_NS, 'lang'))
	{
		return _valid_lang($node->getAttributeNS(XML_XHTML_NS, 'lang')) ?
			$node->getAttributeNS(XML_XHTML_NS, 'lang'):
			undef;
	}

	if ($self->{options}{xhtml_lang}
	and $node->hasAttributeNS(undef, 'lang'))
	{
		return _valid_lang($node->getAttributeNS(undef, 'lang')) ?
			$node->getAttributeNS(undef, 'lang'):
			undef;
	}

	if ($node != $self->{DOM}->documentElement
	and defined $node->parentNode
	and $node->parentNode->nodeType == XML_ELEMENT_NODE)
	{
		return $self->_get_node_lang($node->parentNode);
	}
	
	return $self->{default_language};
}

sub _rdf_triple
# Function only used internally.
{
	my $self = shift;

	my $suppress_triple = 0;
	$suppress_triple = $self->{sub}{pretriple_resource}($self, @_)
		if defined $self->{sub}{pretriple_resource};
	return if $suppress_triple;
	
	my $element   = shift;  # A reference to the XML::LibXML element being parsed
	my $subject   = shift;  # Subject URI or bnode
	my $predicate = shift;  # Predicate URI
	my $object    = shift;  # Resource URI or bnode

	# First make sure the object node type is ok.
	my $to;
	if ($object =~ m/^_:(.*)/)
	{
		$to = RDF::Trine::Node::Blank->new($1);
	}
	else
	{
		$to = RDF::Trine::Node::Resource->new($object);
	}

	# Run the common function
	return $self->_rdf_triple_common($element, $subject, $predicate, $to);
}

sub _rdf_triple_literal
# Function only used internally.
{
	my $self = shift;

	my $suppress_triple = 0;
	$suppress_triple = $self->{sub}{pretriple_literal}($self, @_)
		if defined $self->{sub}{pretriple_literal};
	return if $suppress_triple;

	my $element   = shift;  # A reference to the XML::LibXML element being parsed
	my $subject   = shift;  # Subject URI or bnode
	my $predicate = shift;  # Predicate URI
	my $object    = shift;  # Resource Literal
	my $datatype  = shift;  # Datatype URI (possibly undef or '')
	my $language  = shift;  # Language (possibly undef or '')

	# Now we know there's a literal
	my $to;
	
	# Work around bad Unicode handling in RDF::Trine.
	$object = encode_utf8($object);

	if (defined $datatype)
	{
		if ($datatype eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral')
		{
			if ($self->{options}{use_rtnlx})
			{
				eval
				{
					require RDF::Trine::Node::Literal::XML;
					$to = RDF::Trine::Node::Literal::XML->new($element->childNodes);
				};
			}
			
			if ( $@ || !defined $to)
			{
				my $orig = $RDF::Trine::Node::Literal::USE_XMLLITERALS;
				$RDF::Trine::Node::Literal::USE_XMLLITERALS = 0;
				$to = RDF::Trine::Node::Literal->new($object, undef, $datatype);
				$RDF::Trine::Node::Literal::USE_XMLLITERALS = $orig;
			}
		}
		else
		{
			$to = RDF::Trine::Node::Literal->new($object, undef, $datatype);
		}
	}
	else
	{
		$to = RDF::Trine::Node::Literal->new($object, $language, undef);
	}

	# Run the common function
	$self->_rdf_triple_common($element, $subject, $predicate, $to);
}

sub _rdf_triple_common
# Function only used internally.
{
	my $self      = shift;  # A reference to the HTML::HTML5::Microdata::Parser object
	my $element   = shift;  # A reference to the XML::LibXML element being parsed
	my $subject   = shift;  # Subject URI or bnode
	my $predicate = shift;  # Predicate URI
	my $to        = shift;  # RDF::Trine::Node Resource URI or bnode

	# First, make sure subject and predicates are the right kind of nodes
	my $tp = RDF::Trine::Node::Resource->new($predicate);
	my $ts;
	if ($subject =~ m/^_:(.*)/)
	{
		$ts = RDF::Trine::Node::Blank->new($1);
	}
	else
	{
		$ts = RDF::Trine::Node::Resource->new($subject);
	}

	my $statement = RDF::Trine::Statement->new($ts, $tp, $to);

	my $suppress_triple = 0;
	$suppress_triple = $self->{sub}{ontriple}($self, $element, $statement)
		if ($self->{sub}{ontriple});
	return if $suppress_triple;

	$self->{RESULTS}->add_statement($statement);
}

sub _stringify
# Function only used internally.
{
	my $self = shift;
	my $dom  = shift;
	
	if ($dom->nodeType == XML_TEXT_NODE)
	{
		return $dom->getData;
	}
	elsif ($dom->nodeType == XML_ELEMENT_NODE and lc($dom->tagName) eq 'img')
	{
		return $dom->getAttribute('alt');
	}
	elsif ($dom->nodeType == XML_ELEMENT_NODE)
	{
		return join '',
			map { $self->_stringify($_) }
			$dom->childNodes;
	}

	return '';
}

sub _bnode
# Function only used internally.
{
	my $self    = shift;
	my $element = shift;
	
	return sprintf('http://thing-described-by.org/?%s#%s',
		$self->uri,
		$self->{element}->getAttribute('id'))
		if ($self->{options}{tdb_service}
		and $element
		and length $element->getAttribute('id'));

	return sprintf('_:RDFaAutoNode%03d', $self->{bnodes}++);
}

sub _valid_lang
{
	my $value_to_test = shift;

	return 1 if (defined $value_to_test and $value_to_test eq '');
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

=item $p->graph() 

This method will return an RDF::Trine::Model object with all
statements of the full graph.

=cut

sub graph
{
	my $self = shift;
	$self->consume;
	return $self->{RESULTS};
}

=item $p->graphs() 

Provided for RDF::RDFa::Parser compatibility.

=cut

sub graphs
{
	my $self = shift;
	$self->consume;
	return { $self->{baseuri} => $self->{RESULTS} };
}

sub _auto_config
# Internal use only.
{
	my $self  = shift;
	my $count = 0;
	
	return undef unless $self->{options}{auto_config};

	my $xpc = XML::LibXML::XPathContext->new;
	$xpc->registerNs('x', 'http://www.w3.org/1999/xhtml');
	my $nodes   = $xpc->find('//x:meta[@name="http://search.cpan.org/dist/HTML-HTML5-Microdata-Parser/#auto_config"]/@content', $self->{'DOM'}->documentElement);
	my $optstr = '';
	foreach my $node ($nodes->get_nodelist)
	{
		$optstr .= '&' . $node->getValue;
	}
	$optstr =~ s/^\&//;
	my $options = _parse_axwfue($optstr);
	
	foreach my $o (keys %$options)
	{
		next unless $o=~ /^(alt_stylesheet | mhe_lang | prefix_empty | 
			xhtml_base | xhtml_lang | xhtml_time | xml_lang)$/ix;	
		$count++;
		$self->{options}{lc $o} = $options->{$o};
	}
	
	return $count;
}

sub _parse_axwfue
# Internal use only
{
	my $axwfue = shift;
	$axwfue =~ tr/;/&/;
	$axwfue =~ s/(^&+|&+$)//g;
	my $rv = {};
	for (split /&/, $axwfue)
	{
		my ($k, $v) = split /=/, $_, 2;
		next unless length $k;
		$rv->{uri_unescape($k)} = uri_unescape($v);
	}
	return $rv;
}

1;
__END__

=back

=head1 CALLBACKS

Several callback functions are provided. These may be set using the C<set_callbacks> function,
which taskes a hashref of keys pointing to coderefs. The keys are named for the event to fire the
callback on.

=head2 pretriple_resource

This is called when a triple has been found, but before preparing the triple for
adding to the model. It is only called for triples with a non-literal object value.

The parameters passed to the callback function are:

=over 4

=item * A reference to the C<HTML::HTML5::Microdata::Parser> object

=item * A reference to the C<XML::LibXML::Element> being parsed

=item * Subject URI or bnode (string)

=item * Predicate URI (string)

=item * Object URI or bnode (string)

=back

The callback should return 1 to tell the parser to skip this triple (not add it to
the graph); return 0 otherwise.

=head2 pretriple_literal

This is the equivalent of pretriple_resource, but is only called for triples with a
literal object value.

The parameters passed to the callback function are:

=over 4

=item * A reference to the C<HTML::HTML5::Microdata::Parser> object

=item * A reference to the C<XML::LibXML::Element> being parsed

=item * Subject URI or bnode (string)

=item * Predicate URI (string)

=item * Object literal (string)

=item * Datatype URI (string or undef)

=item * Language (string or undef)

=back

Beware: sometimes both a datatype I<and> a language will be passed. 
This goes beyond the normal RDF data model.)

The callback should return 1 to tell the parser to skip this triple (not add it to
the graph); return 0 otherwise.

=head2 ontriple

This is called once a triple is ready to be added to the graph. (After the pretriple
callbacks.) The parameters passed to the callback function are:

=over 4

=item * A reference to the C<HTML::HTML5::Microdata::Parser> object

=item * A reference to the C<XML::LibXML::Element> being parsed

=item * An RDF::Trine::Statement object.

=back

The callback should return 1 to tell the parser to skip this triple (not add it to
the graph); return 0 otherwise. The callback may modify the RDF::Trine::Statement
object.

=head1 ITEMPROP URI GENERATION STRATEGY

The C<itemprop> attribute does not need to be a full URI.

 <div itemscope itemtype="http://example.com/Person">
   <span itemprop="phoneNumber">01234 567 890</span>
 </div>

The C<strategy> option passed to the constructor tells the parser how to
convert C<phoneNumber> in the above example into a URI. This can be a
callback function, or an object or class that provides a C<generate_uri>
method.

Three strategies are bundled with this distribution:

=over

=item * B<HTML::HTML5::Microdata::Strategy::Basic> - don't attempt to convert to a URI

=item * B<HTML::HTML5::Microdata::Strategy::Heuristic> - smart strategy, the default

=item * B<HTML::HTML5::Microdata::Strategy::Microdata0> - official strategy of early Microdata drafts

=back

=head1 AUTO CONFIG

HTML::HTML5::Microdata::Parser has a lot of different options that can
be switched on and off. Sometimes it might be useful to allow the page
being parsed to control some of the options. If you switch on the
'auto_config' option, pages can do this.

A page can set options using a specially crafted E<lt>metaE<gt> tag:

  <meta name="http://search.cpan.org/dist/HTML-HTML5-Microdata-Parser/#auto_config"
     content="alt_stylesheet=0&amp;prefix_empty=http://example.net/" />

Note that the C<content> attribute is an application/x-www-form-urlencoded
string (which must then be HTML-escaped of course). Semicolons may be used
instead of ampersands, as these tend to look nicer:

  <meta name="http://search.cpan.org/dist/HTML-HTML5-Microdata-Parser/#auto_config"
     content="alt_stylesheet=0;prefix_empty=http://example.net/" />

Any option allowed in the constructor may be given using auto config,
except 'auto_config' itself.

=head1 SEE ALSO

L<XML::LibXML>, L<RDF::Trine>, L<RDF::RDFa::Parser>, 
L<HTML::HTML5::Parser>, L<HTML::HTML5::Sanity>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2009-2011 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
