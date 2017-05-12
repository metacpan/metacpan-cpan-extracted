my $for_the_benefit_of_module_install_metadata = q{
package HTML::HTML5::DOM;
};

{	package HTML::HTML5::DOM;

	use 5.010;
	use strict qw(vars subs);
	use match::simple ();
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::VERSION   = '0.002';
	};
	
	use constant XHTML_NS => 'http://www.w3.org/1999/xhtml';

	my $me;
	BEGIN { $me = bless {}, __PACKAGE__ }

	use DateTime qw//;
	use IO::Detect qw//;
	use Scalar::Util qw/blessed/;
	use URI qw//;

	sub getDOMImplementation
	{
		return $me;
	}

	our @FEATURES = (
		HTML::HTML5::DOMutil::Feature->new(Core       => '3.0'),
		HTML::HTML5::DOMutil::Feature->new(XML        => '3.0'),
		HTML::HTML5::DOMutil::Feature->new(XMLVersion => '1.1'),
		HTML::HTML5::DOMutil::Feature->new(HTML       => '2.0'),
		HTML::HTML5::DOMutil::Feature->new(XHTML      => '2.0'),
	);

	sub getFeature
	{
		my $self = shift;
		my @has  = $self->hasFeature(@_);
		@has ? $has[0] : undef;
	}

	sub hasFeature
	{
		my $self = shift;
		my $test = blessed $_[0] ? $_[0] : HTML::HTML5::DOMutil::Feature->new(@_);
		grep match::simple::match($_, $test), @FEATURES;
	}

	sub registerFeature
	{
		my ($class, $feature) = @_;
		push @FEATURES, $feature;
		$feature->install_subs;
	}

	sub parseString
	{
		my ($self, $string, %options) = @_;
		my $pclass = $options{using} =~ /libxml/i ? 'XML::LibXML' : 'HTML::HTML5::Parser';
		my $dom = $pclass->new->parse_string($string);
		XML::LibXML::Augment->upgrade($dom);
		return $dom;
	}

	sub parse
	{
		my ($self, $file, %options) = @_;
		my $pclass = $options{using} =~ /libxml/i ? 'XML::LibXML' : 'HTML::HTML5::Parser';
		my $dom = IO::Detect::is_filehandle $file
			? $pclass->new->parse_fh($file)
			: $pclass->new->parse_file($file);
		XML::LibXML::Augment->upgrade($dom);
		return $dom;
	}

	sub createDocument
	{
		my $self = shift;
		die "Can only be used to create HTML documents."
			unless (shift//XHTML_NS) eq XHTML_NS;
		die "Can only be used to create HTML documents."
			unless lc(shift//'html') eq 'html';	
		my $dtd = shift//$self->createDocumentType;
		$dtd = $dtd->toString if ref $dtd;
		my $html = "$dtd<html><head></head><body></body></html>";
		my $dom  = $self->parseString($html);
		$dom->setURI('about:blank');
		return $dom;
	}

	sub createDocumentType
	{
		my ($self, $qname, $public, $system) = @_;
		$qname ||= 'html';
		
		if ($public and $system)
		{
			return sprintf('<!DOCTYPE %s PUBLIC "%s" "%s">', $qname, $public, $system);
		}

		elsif ($public)
		{
			return sprintf('<!DOCTYPE %s PUBLIC "%s">', $qname, $public);
		}

		elsif ($system)
		{
			return sprintf('<!DOCTYPE %s PUBLIC "%s">', $qname, $system);
		}

		return sprintf('<!DOCTYPE %s>', $qname);
	}
}

{	package HTML::HTML5::DOMutil::AutoDoc;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';
	
	BEGIN {
		$HTML::HTML5::DOMutil::AutoDoc::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOMutil::AutoDoc::VERSION   = '0.002';
	};

	use Capture::Attribute;

	sub psay
	{
		foreach my $line (@_)
		{
			say $line;
			say "";
		}
	}

	sub add
	{
		my ($class, $package, $sub, $doc) = @_;
		my $docs = \%{"$package\::DOCUMENTATION"};
		$docs->{$sub} = $doc;
	}

	sub pod_for :Capture
	{
		my ($class, $package) = @_;

		my ($interface) = ($package =~ m{ :: ([^:]+) $ }x);

		psay
			q{=head1 NAME},
			"$package - implementation of the $interface interface of the HTML DOM";
		psay
			q{=head1 DESCRIPTION},
			"$package is an implementation of the $interface interface of the HTML DOM. See L<HTML::HTML5::DOM> for a list of the conventions that have been used when translating the DOM to Perl.";

		foreach my $s (qw/_pod_elements _pod_isa _pod_methods/)
		{
			print $class->$s($package);
		}
		
		psay
			q{=head1 BUGS},
			q{L<http://rt.cpan.org/Dist/Display.html?Queue=HTML-HTML5-DOM>.},
			q{=head1 SEE ALSO},
			q{L<HTML::HTML5::DOM>.},
			q{=head1 AUTHOR},
			q{Toby Inkster E<lt>tobyink@cpan.orgE<gt>.},
			q{=head1 COPYRIGHT AND LICENCE},
			q{This software is copyright (c) 2012, 2014 by Toby Inkster.},
			q{This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.},
			q{=head1 DISCLAIMER OF WARRANTIES},
			q{THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.},
			q{};	
	}

	sub _pod_elements :Capture
	{
		my ($class, $package) = @_;

		psay
			q{=head2 HTML Elements},
			q{This class applies to the following HTML elements.},
			q{=over};
		
		my $elements = \@{"$package\::ELEMENTS"};
		
		foreach my $element (sort @$elements)
		{
			psay qq{=item * C<< $element >>};
		}
		
		psay q{=back};
	}

	sub _pod_isa :Capture
	{
		my ($class, $package) = @_;

		psay
			q{=head2 Inheritance},
			qq{$package inherits methods from the following Perl classes.},
			q{=over};
		
		foreach my $parent (@{ mro::get_linear_isa($package) })
		{
			next if $parent eq $package;
			psay qq{=item * L<$parent>};
		}
		
		psay q{=back};
	}

	sub _pod_methods :Capture
	{
		my ($class, $package) = @_;

		my $docs = \%{"$package\::DOCUMENTATION"};

		unless (keys %$docs)
		{
			psay
				q{=head2 Additional Methods},
				q{This class provides no additional methods over those it inherits.},
				q{It is mostly pointless, but its existance is required by the HTML DOM.};
			return;
		}

		psay
			q{=head2 Additional Methods},
			q{As well as its inherited methods, this class provides the following methods.},
			q{=over};
			
		foreach my $meth (sort keys %$docs)
		{
			psay
				qq{=item * C<< $meth >>},
				$docs->{$meth};
		}
		
		psay q{=back};
	}
}

{	package HTML::HTML5::DOMutil::Feature;

	BEGIN {
		$HTML::HTML5::DOMutil::Feature::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOMutil::Feature::VERSION   = '0.002';
	};
	
	use strict qw(vars subs);
	use Carp qw[carp];
	use Scalar::Util qw[blessed];
	use overload
		q[~~]    => 'smart_match',
		q[""]    => 'to_string',
		q[bool]  => sub { 1 },
		fallback => 1,
		;

	sub new
	{
		my $class = shift;
		die sprintf("Usage: %s->new(\$name, \$version)", __PACKAGE__) unless @_==2;
		bless [@_], $class;
	}

	sub feature_name
	{
		lc(shift->[0]);
	}

	sub feature_version
	{
		0+(shift->[1]);
	}

	sub subs
	{
		my $self = shift;
		@$self[2 .. $#$self];
	}

	sub add_sub
	{
		my ($self, $class, $name, $coderef) = @_;
		push @$self, {
			class     => $class,
			name      => $name,
			coderef   => $coderef,
			};
	}

	sub install_subs
	{
		my $self = shift;
		for ($self->subs)
		{
			my ($class, $name, $coderef) = @$_{qw(class name coderef)};
			$class = 'HTML::HTML5::DOM::'.$class unless $class =~ /::/;
			if ($class->can($name))
			{
				carp "$class already has a method called $name. Not replacing.";
			}
			else
			{
				*{"$class\::$name"} = $coderef;
			}
		}
	}

	sub to_string
	{
		my $self = shift;
		sprintf('%s %s', $self->feature_name, $self->feature_version);
	}

	sub smart_match
	{
		my ($self, $test, $swap) = @_;
		($test, $self) = ($self, $test) if $swap;
		
		my ($test_name, $test_version) = do {
			if (blessed $test and $test->isa(__PACKAGE__))
				{ ($test->feature_name, $test->feature_version) }
			elsif (!ref $test)
				{ split /\s+/, $test }
			else
				{ () }
		} or return;
		
		return unless $self->feature_name eq lc($test_name);
		return if defined $test_version and $test_version > $self->feature_version;
		return 1;
	}
}

{	package HTML::HTML5::DOMutil::FancyISA;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';
	
	BEGIN {
		$HTML::HTML5::DOMutil::FancyISA::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOMutil::FancyISA::VERSION   = '0.002';
	};
	
	use Object::AUTHORITY ();
	*AUTHORITY = \&Object::AUTHORITY::AUTHORITY;
	
	sub isa
	{
		my ($self, $isa) = @_;
		
		if ($isa !~ m{::}
		and $self->SUPER::isa('XML::LibXML::Element')
		and $self->tagName eq $isa) {
			return 1;
		}
		
		$isa =~ s/^-/HTML::HTML5::DOM::/;
		return $self->SUPER::isa($isa);
	}
}

{	package HTML::HTML5::DOM::HTMLDocument;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLDocument::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLDocument::VERSION   = '0.002';
	};

	use base qw/HTML::HTML5::DOMutil::FancyISA/;
	use XML::LibXML::Augment 0
		'-type'  => 'Document',
		'-names' => ['{'.HTML::HTML5::DOM->XHTML_NS.'}html'];

	use Carp qw//;

	foreach my $elem (qw/body head/)
	{
		*{$elem} = sub
		{
			my ($self) = @_;
			my ($node1) = $self->getElementsByTagName($elem);
			return $node1;
		};
		
		HTML::HTML5::DOMutil::AutoDoc->add(
			__PACKAGE__,
			$elem,
			"Returns the document ${elem}.",
			);
	}

	{
		my @things = (
			[ images  => '//*[local-name()="img"]',    'images' ],
			[ embeds  => '//*[local-name()="embed"]',  'C<< <embed> >> elements' ],
			[ plugins => '//*[local-name()="embed"]',  'C<< <embed> >> elements' ],
			[ applets => '//*[(local-name()="applet") or (local-name()="object" and @codetype="application/java")]', 'C<< <applet> >> elements (and C<< <object codetype="application/java"> >> elements)' ],
			[ links   => '//*[(local-name()="a" or local-name()="area") and @href]', 'C<< <a> >> and C<< <area> >> elements with an "href" attribute' ],
			[ anchors => '//*[local-name()="a" and @name]', 'C<< <a> >> with a "name" attribute' ],
			[ forms   => '//*[local-name()="form"]',   'forms' ],
			[ scripts => '//*[local-name()="script"]', 'scripts' ],
			[ p5_tables => '//*[local-name()="table"]', 'tables' ],
			);
		foreach my $x (@things)
		{
			*{$x->[0]} = sub
			{
				my ($self) = @_;
				my (@nodes) = $self->findnodes($x->[1]);
				wantarray ? @nodes : HTML::HTML5::DOM::HTMLCollection->new(@nodes);
			};
			HTML::HTML5::DOMutil::AutoDoc->add(
				__PACKAGE__,
				$x->[0],
				"Returns all $x->[2] found in the document.",
				);
		}
	}

	sub compatMode
	{
		my ($self) = @_;
		if (UNIVERSAL::can('HTML::HTML5::Parser', 'can'))
		{
			if (HTML::HTML5::Parser->can('compat_mode'))
			{
				my $mode = HTML::HTML5::Parser->compat_mode($self);
				return $mode if $mode;
			}
		}
		return;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'compatMode',
		"Returns the string 'quirks' or 'limited quirks' or undef.",
		);

	sub URL
	{
		my $self = shift;
		$self->setURI(shift) if @_;
		return URI->new($self->URI);
	}

	*documentURI = \&URL;

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'URL',
		"Get/set the document's URL.",
		);

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'documentURI',
		"Alias for C<URL>.",
		);

	sub domain
	{
		(shift)->URL->host;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'domain',
		"The documents URL's host name.",
		);

	*cookie = *referrer = *referer = sub { q() };

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'cookie',
		"Ostensibly returns cookies associated with the document, but in this implementation always returns an empty string.",
		);

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'referrer',
		"Ostensibly returns the HTTP referer for the document, but in this implementation always returns an empty string.",
		);

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'referer',
		"An alias for 'referrer' provided for the benefit of those who learnt to spell by reading HTTP RFCs.",
		);

	sub lastModified
	{
		return DateTime->now;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'lastModified',
		"Ostensibly returns the HTTP Last-Modified date for the document, but this implementation always returns the current date and time. Returns a L<DateTime> object.",
		);

	{
		my $cs = HTML::HTML::Parser->can('charset');
		
		sub charset
		{
			my $self = @_;
			if (@_)
			{
				$self->setEncoding(@_);
			}
			return $self->encoding;
		}

		HTML::HTML5::DOMutil::AutoDoc->add(
			__PACKAGE__,
			'charset',
			"Getter/setter for the document encoding.",
			);

		sub defaultCharset
		{
			return 'utf-8';
		}

		HTML::HTML5::DOMutil::AutoDoc->add(
			__PACKAGE__,
			'defaultCharset',
			"Returns the string 'utf-8'.",
			);

		sub characterSet
		{
			return unless $cs;
			return $cs->( shift );
		}
		
		HTML::HTML5::DOMutil::AutoDoc->add(
			__PACKAGE__,
			'characterSet',
			"Returns the character set that the document was parsed as (if known). As C<charset> can be used as a setter, this is not necessarily the same as C<charset>.",
			);
	}

	sub readyState
	{
		'complete';
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'lastModified',
		"Ostensibly returns the current document readiness, but this implementation always returns the string 'complete'.",
		);

	sub title
	{
		my ($self) = @_;
		my ($title) = $self->getElementsByTagName('title')->get_node(1)->textContent;
		$title =~ s/\s+/ /g;
		$title =~ s/(^\s|\s$)//g;
		return $title;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'title',
		"Returns the document's title, from its C<< <title> >> element, with a little whitespace canonicalisation.",
		);

	sub getElementById
	{
		my ($self, $id) = @_;
		my @nodes = $self->findnodes("*[\@id=\"$id\"]");
		return $nodes[0];
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'getElementById',
		'The world-famous C<getElementById> method. The default XML::LibXML implementation of this does not work with HTML::HTML5::Parser documents, because HTML::HTML5::Parser lacks the ability to inform libxml which element to use as an ID. (libxml defaults to xml:id.) This implementation is XPath-based, thus slower.',
		);

	*getElementsById = \&getElementById; # common typo

	sub xmlVersion
	{
		my $self = shift;
		return undef
			if defined HTML::HTML5::Parser->source_line($self);
		return $self->version;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'xmlVersion',
		"Returrns undef for documents parsed using an HTML parser; 1.0 or 1.1 if parsed using libxml.",
		);

	our $AUTOLOAD;
	sub AUTOLOAD
	{
		my $self = shift;
		my ($func) = ($AUTOLOAD =~ m{ :: (\w+) $ }x);
		if ($func)
		{
			my $coderef = HTML::HTML5::DOM::HTMLHtmlElement->can($func);
			if ($coderef)
			{
				unshift @_, $self->documentElement;
				goto $coderef;
			}
		}
		Carp::croak "Method '$AUTOLOAD' could not be autoloaded";
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'AUTOLOAD',
		"See L<perlsub> if you don't know the significance of the AUTOLOAD function. HTML::HTML5::DOM::HTMLDocument will pass through unknown menthods to the document's root element. So for example, C<< \$document->setAttribute >> will actually set an attribute on the document's root element.",
		);

	sub implementation { HTML::HTML5::DOM->getDOMImplementation }

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'implementation',
		"Returns the same as HTML::HTML5::DOM->getDOMImplementation.",
		);

	sub xmlStandalone
	{
		my $self = shift;
		$self->setStandalone(@_) if @_;
		$self->standalone;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'xmlStandalone',
		"Called with an argument, acts as C<setStandalone>; called without an argument, acts as C<standalone>.",
		);

	sub strictErrorChecking { return; }

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'strictErrorChecking',
		"DOM seems a little vague as to what exactly constitutes 'strict'. This returns false.",
		);

	*normalizeDocument = __PACKAGE__->can('normalize');

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'normalizeDocument',
		"Alias for C<normalize>.",
		);

	sub domConfig
	{
		state $domConfig = +{};
		return $domConfig;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'domConfig',
		"Ostensibly an object representing settings which will be used when C<normalize> is called. In practise, just returns an empty hashref that you can do with what you like.",
		);

	*renameNode =
	*doctype =
	*inputEncoding =
	*xmlEncoding =
	sub { die "TODO" };

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		$_,
		"This method is not implemented yet, but will eventually support the functionality defined in DOM Core 3.",
		) for qw(renameNode doctype inputEncoding xmlEncoding);
}
	
{	package HTML::HTML5::DOM::HTMLCollection;

	use 5.010;
	use strict;
	use mro 'c3';
	
	BEGIN {
		$HTML::HTML5::DOM::HTMLCollection::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLCollection::VERSION   = '0.002';
	};
	
	use base qw/
		XML::LibXML::NodeList
		HTML::HTML5::DOMutil::FancyISA
	/;
}

{	package HTML::HTML5::DOM::HTMLElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLElement::VERSION   = '0.002';
	};

	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/abbr address article aside b bdi bdo cite code
				dd dfn dt em figcaption figure footer header
				hgroup i kbd mark nav noscript rp rt ruby s samp
				section small strong sub summary sup u var wbr/;
	}

	use HTML::HTML5::Parser 0.110;
	use HTML::HTML5::Writer 0.104;
	use List::Util 0 qw//;
	use Scalar::Util 0 qw//;
	use HTTP::Request 6.00 qw//;
	use XML::LibXML 1.91 qw/:all/;
	use XML::LibXML::Augment 0 -names => [@ELEMENTS];
	use XML::LibXML::QuerySelector 0;

	use base qw/HTML::HTML5::DOMutil::FancyISA/;

	sub _mk_attribute_accessors
	{
		my ($class, @attribs) = @_;
		foreach (@attribs)
		{
			my ($subname, $xmlname, $type) = split /=/;
			$xmlname ||= $subname;
					
			if ($type eq 'LIST')
			{
				*{"$class\::$subname"} = sub
				{
					my $self = shift;
					my $i = 1;
					my %seen;
					return 
						grep { not $seen{$_}++ } # filter out duplicates
						grep { length $_ }       # ignore nulls
						split /\s+/,             # space separated list
						$self->getAttribute($xmlname);
				};
				HTML::HTML5::DOMutil::AutoDoc->add(
					$class,
					$subname,
					sprintf(
						'Splits C<< $elem->getAttribute("%s") >> into a list on whitespace.',
						$xmlname,
						),
					);
			}
			elsif ($type eq 'URI' || $type eq 'URL')
			{
				*{"$class\::$subname"} = sub
				{
					my $elem = shift;
					if (@_)
					{
						my $newval = shift;
						defined $newval ?
							$elem->setAttribute($xmlname, $newval) :
							$elem->removeAttribute($xmlname);
					}
					my $base = $elem->baseURI // $elem->ownerDocument->URI;
					return $base ?
						URI->new_abs($elem->getAttribute($xmlname), $base):
						URI->new($elem->getAttribute($xmlname));
				};
				HTML::HTML5::DOMutil::AutoDoc->add(
					$class,
					$subname,
					sprintf(
						'Called with no arguments, is a shortcut for C<< $elem->getAttribute("%s") >> but as a blessed L<URI> object. Called with a defined argument, acts as C<setAttribute>. Called with undef as an argument, acts as C<removeAttribute>.',
						$xmlname,
						),
					);
			}
			elsif ($type eq 'TEXT')
			{
				*{"$class\::$subname"} = sub
				{
					my $self = shift;
					if (@_)
					{
						$self->removeChildNodes;
						$self->appendText(join qq(\n), @_);
					}
					$self->textContent;
				};
				HTML::HTML5::DOMutil::AutoDoc->add(
					$class,
					$subname,
					sprintf(
						'Called with no arguments, acts as an alias for C<< $elem->textContent >>. Called with an arguments, sets the content for the element. Any existing content will be overwritten. If multiple arguments are provided, they\'ll be joined using "\n".',
						),
					);
			}
			elsif ($type eq 'boolean')
			{
				*{"$class\::$subname"} = sub
				{
					my $elem = shift;
					if (@_)
					{
						my $newval = shift;
						$newval ?
							$elem->setAttribute($xmlname, $xmlname) :
							$elem->removeAttribute($xmlname);
					}
					$elem->hasAttribute($xmlname)
				};
				HTML::HTML5::DOMutil::AutoDoc->add(
					$class,
					$subname,
					sprintf(
						'Called with no arguments, is a shortcut for C<< $elem->hasAttribute("%s") >>. If called with a true argument, will C<setAttribute>; if called with a false argument will C<removeAttribute>.',
						$xmlname,
						),
					);
			}
			else
			{
				*{"$class\::$subname"} = sub
				{
					my $elem = shift;
					if (@_)
					{
						my $newval = shift;
						defined $newval ?
							$elem->setAttribute($xmlname, $newval) :
							$elem->removeAttribute($xmlname);
					}
					$elem->{$xmlname}
				};
				HTML::HTML5::DOMutil::AutoDoc->add(
					$class,
					$subname,
					sprintf(
						'Called with no arguments, is a shortcut for C<< $elem->getAttribute("%s") >>. Called with a defined argument, acts as C<setAttribute>. Called with undef as an argument, acts as C<removeAttribute>.',
						$xmlname,
						),
					);
			}
		}
	}

	sub _mk_url_decomposition
	{
		my ($class, $via, $bits) = @_;
		$via  ||= 'href';
		$bits ||= {
			protocol => 'scheme',
			host     => 'host_port',
			hostname => 'host',
			port     => 'port',
			pathname => 'path',
			search   => 'query',
			hash     => 'fragment',
			};
		foreach my $bit (keys %$bits)
		{
			my $method = $bits->{$bit};
			*{"$class\::$bit"} = sub { (shift)->$via->$method };
			HTML::HTML5::DOMutil::AutoDoc->add(
				$class,
				$bit,
				sprintf(
					'A shortcut for C<< $elem->%s->%s >>. (Does not act as a setter.)',
					$via,
					$method,
					),
				);
		}
	}

	sub _mk_labels_method
	{
		my ($class, $subname) = @_;
		$subname ||= 'labels';
		
		*{"$class\::$subname"} = sub {
			my $self = shift;
			my @labels = grep
				{ $_->can('control') && $_->control eq $self }
				$self->ownerDocument->getElementsByTagName('label');
			return wantarray ? @labels : XML::LibXML::NodeList->new(@labels);
		};

		HTML::HTML5::DOMutil::AutoDoc->add(
			$class,
			$subname,
			'A list of C<< <label> >> elements which label this element.',
			);
	}

	sub _mk_follow_method
	{
		my ($class, $subname, $via) = @_;
		$subname ||= 'p5_follow';
		$via     ||= 'href';
		
		*{"$class\::$subname"} = sub {
			my $self = shift;
			my $url  = $self->$via;
			return HTTP::Request->new(GET => "$url");
		};

		HTML::HTML5::DOMutil::AutoDoc->add(
			$class,
			$subname,
			sprintf('Shortcut for C<< HTTP::Request->new(GET => $elem->%s) >>', $via),
			);
	}

	sub _mk_form_methods
	{
		my ($class, $todo) = @_;
		$todo ||= sub { 1 };
		
		if (match::simple::match('form', $todo))
		{
			*{"$class\::form"} = sub
			{
				my $self = shift;
				if ($self->hasAttribute('form'))
				{
					my $form = $self->documentElement->getElementById(
						$self->getAttribute('form'));
					return $form if $form;
				}
				return
					List::Util::first { $_->nodeName eq 'form' }
					$self->p5_ancestors;
			};
			HTML::HTML5::DOMutil::AutoDoc->add(
				$class,
				'form',
				'Returns the "form owner" for this element.',
				);
		}
		
		foreach my $x (qw/Action Enctype Method NoValidate Target/)
		{
			next unless match::simple::match(lc("form$x"), $todo);
			
			*{"$class\::form$x"} = sub
			{
				my $self = shift;
				if ($self->hasAttribute(lc "form$x"))
				{
					return $self->getAttribute(lc "form$x")
				}
				return $self->form->getAttribute(lc $x);
			};
			HTML::HTML5::DOMutil::AutoDoc->add(
				$class,
				'form',
				sprintf('Returns the "form%s" attribute for this element if it exists, or otherwise the "%s" attribute of this element\'s form owner.', lc $x, lc $x),
				);
		}
	}

	sub getElementById
	{
		my ($self, $id) = @_;
		my @nodes = $self->findnodes("*[\@id=\"$id\"]");
		return $nodes[0];
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'getElementById',
		'The world-famous C<getElementById> method. The default XML::LibXML implementation of this does not work with HTML::HTML5::Parser documents, because HTML::HTML5::Parser lacks the ability to inform libxml which element to use as an ID. (libxml defaults to xml:id.) This implementation is XPath-based, thus slower.',
		);

	*getElementsById = \&getElementById; # common typo

	sub getElementsByClassName
	{
		my $self = shift;
		my $conditions = join q{ or },
			map { "contains(concat(' ', normalize-space(\@class), ' '), ' $_ ')" }
			@_;
		my @rv = $self->findnodes("*[$conditions]");
		return wantarray ? @rv : HTML::HTML5::DOM::HTMLCollection->new(@rv);
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'getElementsByClassName',
		'Given one or more class names, returns a list of elements bearing those classes.',
		);

	sub outerHTML
	{
		my $self = shift;
		
		if (@_)
		{
			my $parser = HTML::HTML5::Parser->new;
			if ($self->parentNode and $self->parentNode->nodeType==XML_ELEMENT_NODE)
			{
				my @nodes = $parser->parse_balanced_chunk(
					(join qq(\n), @_),
					{ within => $self->parentNode->nodeName, as => 'list' },
					);
				$self->parentNode->insertBefore($_, $self) for @nodes;
				$self->parentNode->removeChild($self);
			}
			else
			{
				$self
					-> ownerDocument
					-> setDocumentElement(
						$parser->parse_string(join qq(\n), @_)->documentElement
						);
			}
			return join qq(\n), @_;
		}
		
		my $writer = HTML::HTML5::Writer->new(markup => 'html', polyglot => 1);
		$writer->element($self);
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'outerHTML',
		'As per innerHTML, but includes the element itself. Can be used as a setter, but that\'s a bit of a weird thing to do.',
		);

	sub innerHTML
	{
		my $self = shift;
		if (@_)
		{
			my $parser = HTML::HTML5::Parser->new;
			my @nodes  = $parser->parse_balanced_chunk(
				(join qq(\n), @_),
				{ within => $self->nodeName, as => 'list' },
				);
			$self->removeChildNodes;
			$self->appendChild($_) for @nodes;
		}
		
		my $writer;
		join q{},
			map
			{ 
				$writer ||= HTML::HTML5::Writer->new(markup => 'html', polyglot => 1);
				
				if ($_->nodeType == XML_ELEMENT_NODE)
				{
					$writer->element($_)
				}
				elsif ($_->nodeType == XML_TEXT_NODE)
				{
					$writer->text($_)
				}
				else
				{
					$_->toString
				}
			}
			$self->childNodes	
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'innerHTML',
		'When called without arguments, serialises the contents of the element (but not the element itself) to a single string. When called with a string argument, parses the string as HTML and uses it to set the content of this element. When possible, attempts to use polyglot HTML (i.e. markup that works as HTML and XHTML).',
		);

	sub p5_ancestors
	{
		my ($self) = @_;
		my $x = $self->parentNode;
		my @rv;
		while (defined $x and Scalar::Util::blessed $x and $x->isa('XML::LibXML::Element'))
		{
			push @rv, $x;
			$x = $x->parentNode;
		}
		return wantarray ? @rv : HTML::HTML5::DOM::HTMLCollection->new(@rv);
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'p5_ancestors',
		'Returns a (Perl or XML::LibXML::NodeList) list of this element\'s ancestors - i.e. the parentNode, the parentNode of the parentNode, etc.',
		);

	sub p5_contains
	{
		my ($self, $thing) = @_;
		my @results = grep {
			$_ == $self
		} $thing->p5_ancestors;
		return 1 if @results;
		return;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'p5_contains',
		'Given an argument, returns true if that argument is an element nested within this element.',
		);

	__PACKAGE__->_mk_attribute_accessors(qw/
		id
		title lang translate==boolean dir className=class
		hidden==boolean tabIndex=tabindex accessKey=accesskey
		classList=class=LIST
		/);

	sub dataset
	{
		my $self = shift;
		my %rv;
		foreach my $attr ($self->attributes)
		{
			if ($attr->nodeName =~ /^data-[^A-Z]$/)
			{
				my $key = $1;
				$key =~ s{ \- ([a-z]) }{ uc('-'.$1) }gex;
				$rv{$key} = $attr->value;
			}
		}
		return \%rv;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'dataset',
		'Gets a hashref based on C<< data-foo >> attributes. This is currently read-only, but in future may be implemented as a tied hash to allow read/write access.',
		);

	sub XML::LibXML::Node::_p5_numericPath
	{
		join q{:},
			map { sprintf('%09d', $_) }
			map {
				if (m{^[*]\[(\d+)]$})   { $1; }
				elsif (m{^[*]$})       { 0; }
				elsif (m{^$})          { 0; }
				else                   { 999_999_999 }
			}
			split m{/}, (shift)->nodePath;
	}

	sub compareDocumentPosition
	{
		my ($self, $other) = @_;
		$self->_p5_numericPath cmp $other->_p5_numericPath;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'compareDocumentPosition',
		'Compares this node with another based on document order.',
		);

	*getUserData =
	*setUserData =
	sub { die "TODO" };

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		$_,
		'Not implemented - perhaps never will be. Try C<dataset> instead.',
		) for qw( getUserData setUserData );

	sub getFeature { (shift)->ownerDocument->implementation->getFeature(@_) }

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'getFeature',
		'Acts as a shortcut for C<< $element->ownerDocument->implementation->getFeature >>.',
		);

	sub isDefaultNamespace { my $self = shift; !$self->lookupNamespacePrefix("".shift) }

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'isDefaultNamespace',
		'Given a URI, returns true if that is the default namespace prefix.',
		);

	*lookupPrefix = XML::LibXML::Augment::Element->can('lookupNamespacePrefix');

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'lookupPrefix',
		'Alias for C<lookupNamespacePrefix>.',
		);

	sub isSupported { (shift)->ownerDocument->implementation->hasFeature(@_) }

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'isSupported',
		'Acts as a shortcut for C<< $element->ownerDocument->implementation->hasFeature >>.',
		);

	*schemaTypeInfo =
	*setIdAttribute =
	*setIdAttributeNS =
	*setIdAttributeNode =
	sub { die "TODO" };

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		$_,
		'Not implemented.',
		) for qw( schemaTypeInfo setIdAttribute setIdAttributeNS setIdAttributeNode );
}
	
{	package HTML::HTML5::DOM::HTMLUnknownElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLUnknownElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLUnknownElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/*/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];
}
	
{	package HTML::HTML5::DOM::HTMLAnchorElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLAnchorElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLAnchorElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) } qw/a/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/
		href==URI target rel rev media hreflang target type
		relList=rel=LIST revList=rev=LIST text==TEXT
		name
		/);
	__PACKAGE__->_mk_url_decomposition;
	__PACKAGE__->_mk_follow_method;
}

{	package HTML::HTML5::DOM::HTMLAreaElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLAreaElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLAreaElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/area/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/
		alt coords shape href==URI target rel rev media hreflang type
		relList=rel=LIST revList=rev=LIST
		/);
	__PACKAGE__->_mk_url_decomposition;
	__PACKAGE__->_mk_follow_method;
}

{	package HTML::HTML5::DOM::HTMLAudioElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLAudioElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLAudioElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/audio/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLMediaElement'];
}
	
{	package HTML::HTML5::DOM::HTMLMediaElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLMediaElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLMediaElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw//;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/
		src==URI crossOrigin=crossorigin preload controls
		/);
	__PACKAGE__->_mk_follow_method('src');
}

{	package HTML::HTML5::DOM::HTMLBaseElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLBaseElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLBaseElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/base/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/href==URI target/);
	__PACKAGE__->_mk_url_decomposition;
}

{	package HTML::HTML5::DOM::HTMLQuoteElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLQuoteElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLQuoteElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/blockquote q/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/cite==URI/);
}

{	package HTML::HTML5::DOM::HTMLBodyElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLBodyElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLBodyElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/body/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];
}

{	package HTML::HTML5::DOM::HTMLBRElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLBRElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLBRElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/br/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];
}

{	package HTML::HTML5::DOM::HTMLButtonElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLButtonElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLButtonElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/button/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/autofocus disabled name type value/);
	__PACKAGE__->_mk_labels_method;
	__PACKAGE__->_mk_form_methods;
}

{	package HTML::HTML5::DOM::HTMLCanvasElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLCanvasElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLCanvasElement::VERSION   = '0.002';
	};
		
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/canvas/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/height width/);
}

{	package HTML::HTML5::DOM::HTMLTableCaptionElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLTableCaptionElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLTableCaptionElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/caption/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];
}
	
{	package HTML::HTML5::DOM::HTMLTableColElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLTableColElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLTableColElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/col colgroup/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	sub span
	{
		my $self = shift;
		
		if (@_)
		{
			my $set = shift;
			int($set) > 0
				? $self->setAttribute(span => int($set))
				: $self->removeAttribute('span')
		}
		
		my $span = $self->getAttribute('span');
		int($span) > 0 ? int($span) : 1;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		span => 'Accessor for the C<< span >> attribute. Must always be a positive integer.',
	);
}

{	package HTML::HTML5::DOM::HTMLCommandElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLCommandElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLCommandElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/command/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/
		type label icon==URI disabled==boolean checked==boolean radiogroup
		/);
}
	
{	package HTML::HTML5::DOM::HTMLDataListElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLDataListElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLDataListElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/datalist/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	sub options
	{
		my ($self) = @_;
		return $self->getElementsByTagName('option');
	}
}

{	package HTML::HTML5::DOM::HTMLModElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLModElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLModElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/del ins/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/cite==URI dateTime=datetime=datetime/);
}

{	package HTML::HTML5::DOM::HTMLDetailsElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLDetailsElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLDetailsElement::VERSION   = '0.002';
	};
		
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/details/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/open==boolean/);
}

{	package HTML::HTML5::DOM::HTMLDivElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLDivElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLDivElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/div/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];
}

{	package HTML::HTML5::DOM::HTMLDListElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLDListElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLDListElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/dl/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];
}

{	package HTML::HTML5::DOM::HTMLEmbedElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLEmbedElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLEmbedElement::VERSION   = '0.002';
	};
		
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/embed/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/src==URI type height width/);
}

{	package HTML::HTML5::DOM::HTMLFieldSetElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLFieldSetElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLFieldSetElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/fieldset/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/disabled==boolean name/);
	__PACKAGE__->_mk_form_methods([qw/form/]);

	sub type
	{
		return 'fieldset';
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'type',
		'Returns the string "fieldset". Kinda useless, but it is part of the HTML5 DOM.',
		);

	sub elements
	{
		die "TODO";
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'elements',
		'@@TODO - should return a list of C<< <input> >>, C<< <select> >>, etc elements nested inside this fieldset.',
		);
}

{	package HTML::HTML5::DOM::HTMLFormElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLFormElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLFormElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/form/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/
		acceptCharset=accept-charset action==URI autocomplete enctype
		encoding method name noValidate=novalidate target
		/);

	sub _get_elements
	{
		my ($self, $allowed) = @_;
		my $return = $self
			-> ownerDocument
			-> getElementsByTagName('*')
			-> grep(sub {
					match::simple::match($_->nodeName, $allowed)
					&& ($_->form == $self)
				})
			-> map(sub { XML::LibXML::Augment->rebless($_) });
		wantarray ?
			$return->get_nodelist :
			bless($return, 'HTML::HTML5::DOM::HTMLFormControlsCollection');
	}

	sub elements
	{	
		my $self = shift;
		@_ = ($self, [qw/button fieldset input keygen object output select textarea/]);
		goto \&_get_elements;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'elements',
		'Returns a list of form-related elements which this form owns. In list context this is a normal Perl list. In scalar context it is a HTML::HTML5::DOM::HTMLFormControlsCollection.',
		);

	sub p5_submittableElements
	{
		my $self = shift;
		@_ = ($self, [qw/button input keygen object select textarea/]);
		goto \&_get_elements;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'p5_submittableElements',
		'Returns a list of form-related elements which this form owns that can potentially cause name=value pairs to be added to the form submission. (e.g. not C<< <fieldset> >>.) In list context this is a normal Perl list. In scalar context it is a HTML::HTML5::DOM::HTMLFormControlsCollection.',
		);

	sub length
	{
		my $self = shift;
		return $self->elements->size;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'length',
		'The length of the C<elements> list.',
		);

	sub submit
	{
		my ($self, $hashref) = @_;

		my $method = (uc $self->method || 'GET');
		my $fields = $self->p5_submittableElements->p5_wwwFormUrlencoded($hashref);

		if ($method eq 'GET')
		{
			return HTTP::Request->new(GET => $self->action.'?'.$fields)
		}

		HTTP::Request->new(
			$method,
			$self->action,
			[ 'Content-Type' => $self->enctype || 'application/x-www-form-urlencoded' ],
			$fields,
		);
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'submit',
		'Submits the form based on the current values of its submittable elements. May be passed an optional hashref of name=>value pairs to override those values, but this is not always enough to do what you want, as HTML allows for multiple form elements of the same name to exist in a form.',
		);
}

{	package HTML::HTML5::DOM::HTMLFormControlsCollection;

	BEGIN {
		$HTML::HTML5::DOM::HTMLFormControlsCollection::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLFormControlsCollection::VERSION   = '0.002';
	};
	
	use base qw/HTML::HTML5::DOM::HTMLCollection/;
	use URI::Escape qw//;

	sub namedItem
	{
		my ($self, $name) = @_;
		my @items = $self->grep(sub {
			($_->hasAttribute('id') && $_->getAttribute('id') eq $name) ||
			($_->hasAttribute('name') && $_->getAttribute('name') eq $name)
		});
		return $items[0] if scalar @items == 1;
		return wantarray ? @items : HTML::HTML5::DOM::RadioNodeList->new(@items);
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'namedItem',
		'Given a name, returns a list of nodes of elements where the @id or @name attribute matches that name. In scalar context this can return a single element if there\'s only one match, or a HTML::HTML5::DOM::RadioNodeList if there is more than one - this is a kinda annoying feature, but it is required for DOM compliance. Best to just call it in list context.',
		);

	sub p5_wwwFormUrlencoded
	{
		my ($self, $hashref) = @_;
		my @pairs = $self->p5_wwwFormPairs($hashref);
		#use Data::Dumper; print Dumper \@pairs; exit;
		return
			join '&',
			map {
				sprintf('%s=%s', map { URI::Escape::uri_escape($_) } @$_)
			}
			@pairs;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'p5_wwwFormUrlencoded',
		'Returns a form-encoded (C<< foo=bar&quux=xyzzy >>) string for the elements on the list.',
		);

	sub p5_wwwFormPairs
	{
		my ($self, $hashref) = @_;
		my %remaining = my %HH = %{ $hashref || +{} };
		my $return = $self->map(sub {
			my @empty;
			return @empty unless $_->can('p5_wwwFormPair');
			my $pair = $_->p5_wwwFormPair;
			return @empty unless $pair;
			if (exists $hashref->{$pair->[0]})
			{
				delete $remaining{ $pair->[0] };
				$pair->[1] = $hashref->{$pair->[0]};
			}
			return $pair;
		});
		while (my @pair = each %remaining)
		{
			$return->push(\@pair);
		}
		wantarray ? @$return : (bless $return, 'XML::LibXML::NodeList');
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'p5_wwwFormPairs',
		'Returns a list of C<< [$name => $value] >> tuples for the elements on the list.',
		);
}

{	package HTML::HTML5::DOM::RadioNodeList;

	use 5.010;
	use strict;
	use mro 'c3';
	use Object::AUTHORITY;

	BEGIN {
		$HTML::HTML5::DOM::RadioNodeList::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::RadioNodeList::VERSION   = '0.002';
	};
		
	use base qw/XML::LibXML::NodeList/;

	sub value
	{
		my ($self) = @_;
		my @items = $self->grep(sub { $_->hasAttribute('checked') });
		return unless @items;
		return unless $items[0]->hasAttribute('value');
		return $items[0]->getAttribute('value');
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'p5_wwwFormPairs',
		'Returns the "value" attribute of the first element which has a "checked" attribute.',
		);
}

{	package HTML::HTML5::DOM::HTMLHeadElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLHeadElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLHeadElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/head/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	sub profile
	{
		my ($self) = @_;
		return
			map { URI->new($_) }
			grep { length $_ }
			split /\s+/,
			$self->getAttribute('profile');
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'p5_wwwFormPairs',
		'Splits the "profile" attribute on whitespace, and returns it as a list of L<URI> objects.',
		);
}

{	package HTML::HTML5::DOM::HTMLHeadingElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLHeadingElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLHeadingElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/h1 h2 h3 h4 h5 h6/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];
}

{	package HTML::HTML5::DOM::HTMLHRElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLHRElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLHRElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/hr/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];
}

{	package HTML::HTML5::DOM::HTMLHtmlElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLHtmlElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLHtmlElement::VERSION   = '0.002';
	};
		
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/html/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/version/);
}

{	package HTML::HTML5::DOM::HTMLIFrameElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLIFrameElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLIFrameElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/iframe/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(
		qw/src==URI srcdoc name sandbox seamless==boolean width height/
		);
}

{	package HTML::HTML5::DOM::HTMLImageElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLImageElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLImageElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/img/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(
		qw/alt src==URI crossOrigin=crossorigin useMap=usemap isMap=ismap width height/
		);
	__PACKAGE__->_mk_follow_method('src');
}

{	package HTML::HTML5::DOM::HTMLInputElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLInputElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLInputElement::VERSION   = '0.002';
	};
		
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/input/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(
		qw/accept alt max min multiple==boolean pattern placeholder
		required==boolean size src==URI step autocomplete type
		dirName=dirname autofocus==boolean checked==boolean width
		maxLength=maxlength height name readOnly=readonly=boolean/
		);
	__PACKAGE__->_mk_labels_method;
	__PACKAGE__->_mk_form_methods;

	*indeterminate =
	*list =
	*valueAsDate =
	*valueAsNumber =
	*stepUp =
	*stepDown =
		sub { die 'TODO' };

	sub p5_wwwFormPair
	{
		my ($self) = @_;
		if ($self->getAttribute('type') =~ m{^ (checkbox|radio) $}ix)
		{
			return unless $self->hasAttribute('checked');
		}
		elsif ($self->getAttribute('type') =~ m{^ (submit|reset|button|image) $}ix)
		{
			return;
		}
		
		return [ $self->getAttribute('name'), $self->getAttribute('value') ];
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'p5_wwwFormPair',
		'Returns the C<< [$name => $value] >> that would be used when submitting this form element.',
		);
}

{	package HTML::HTML5::DOM::HTMLKeygenElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLKeygenElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLKeygenElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/keygen/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_labels_method;
	__PACKAGE__->_mk_form_methods([qw/form/]);
}

{	package HTML::HTML5::DOM::HTMLLabelElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLLabelElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLLabelElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/label/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_form_methods([qw/form/]);

	sub control
	{
		my ($self) = @_;
		
		my @controls;
		if ($self->hasAttribute('for'))
		{
			my $xpath = sprintf('//[@id="%s"]', $self->getAttribute('for'));
			@controls = $self->ownerDocument->findnodes($xpath);
		}
		else
		{
			@controls = grep { $_->can('labels') } $self->getElementsByTagName('*');
		}
		
		return $controls[0] if @controls;
		return;	
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'control',
		'Returns the control that this element acts as a label for.',
		);
}

{	package HTML::HTML5::DOM::HTMLLegendElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLLegendElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLLegendElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/legend/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_form_methods([qw/form/]);
}

{	package HTML::HTML5::DOM::HTMLLIElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLLIElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLLIElement::VERSION   = '0.002';
	};
		
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/li/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	sub value
	{
		die "TODO";
	}
}

{	package HTML::HTML5::DOM::HTMLLinkElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLLinkElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLLinkElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/link/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/
		disabled==boolean href==URI rel rev media hreflang target type
		relList=rel=LIST revList=rev=LIST
		/);
	__PACKAGE__->_mk_url_decomposition; # technically not part of HTML5 spec
	__PACKAGE__->_mk_follow_method;
}

{	package HTML::HTML5::DOM::HTMLMapElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLMapElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLMapElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/map/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];
}

{	package HTML::HTML5::DOM::HTMLMenuElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLMenuElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLMenuElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/menu/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/label type/);
}

{	package HTML::HTML5::DOM::HTMLMetaElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLMetaElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLMetaElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/meta/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/name httpEquiv=http-equiv content scheme/);
}

{	package HTML::HTML5::DOM::HTMLMeterElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLMeterElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLMeterElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/meter/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/value min max low high optimum/);
	__PACKAGE__->_mk_labels_method;
	__PACKAGE__->_mk_form_methods([qw/form/]);
}

{	package HTML::HTML5::DOM::HTMLObjectElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLObjectElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLObjectElement::VERSION   = '0.002';
	};

	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/object/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(
		qw/data==URI type typeMustMatch=typemustmatch name useMap=usemap width height/
		);
	__PACKAGE__->_mk_form_methods([qw/form/]);
	__PACKAGE__->_mk_follow_method('data');
}

{	package HTML::HTML5::DOM::HTMLOListElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLOListElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLOListElement::VERSION   = '0.002';
	};

	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/ol/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/reversed==boolean start type/);
}

{	package HTML::HTML5::DOM::HTMLOptGroupElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLOptGroupElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLOptGroupElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/optgroup/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/disabled==boolean label/);
}

{	package HTML::HTML5::DOM::HTMLOptionElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLOptionElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLOptionElement::VERSION   = '0.002';
	};
		
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/option/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];
}
	
{	package HTML::HTML5::DOM::HTMLOutputElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLOutputElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLOutputElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/output/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_labels_method;
	__PACKAGE__->_mk_form_methods([qw/form/]);
}

{	package HTML::HTML5::DOM::HTMLParagraphElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLParagraphElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLParagraphElement::VERSION   = '0.002';
	};
		
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/p/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];
}

{	package HTML::HTML5::DOM::HTMLParamElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLParamElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLParamElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/param/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/name value/);
}

{	package HTML::HTML5::DOM::HTMLPreElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLPreElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLPreElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/pre/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];
}

{	package HTML::HTML5::DOM::HTMLProgressElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLProgressElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLProgressElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/progress/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/max position value/);
	__PACKAGE__->_mk_labels_method;
}

{	package HTML::HTML5::DOM::HTMLScriptElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLScriptElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLScriptElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/script/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(
		qw/src==URI async==boolean defer==boolean type charset text==TEXT/
		);
}

{	package HTML::HTML5::DOM::HTMLSelectElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLSelectElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLSelectElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/select/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_labels_method;
	__PACKAGE__->_mk_form_methods([qw/form/]);
}

{	package HTML::HTML5::DOM::HTMLSourceElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLSourceElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLSourceElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/source/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(
		qw/src==URI type media/
		);
	__PACKAGE__->_mk_follow_method('src');
}

{	package HTML::HTML5::DOM::HTMLSpanElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLSpanElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLSpanElement::VERSION   = '0.002';
	};
		
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/span/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];
}

{	package HTML::HTML5::DOM::HTMLStyleElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLStyleElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLStyleElement::VERSION   = '0.002';
	};
		
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/style/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(
		qw/disabled==boolean scoped==boolean type media/
		);
}

{	package HTML::HTML5::DOM::HTMLTableElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLTableElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLTableElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/table/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	sub caption
	{
		my $self  = shift;
		my ($cap) = $self->getChildrenByTagName('caption');
		return $cap if $cap;
		return;
	}

	sub createCaption
	{
		my $self = shift;
		return $self->caption || do {
			my $new = XML::LibXML::Element->new('caption');
			$new->setNamespace($self->namespaceURI, '', 1);
			$self->insertBefore($new, $self->childNodes->get_node(1));
			XML::LibXML::Augment->rebless($new);
			$new;
		};
	}

	sub deleteCaption
	{
		my $self = shift;
		my $cap  = $self->caption;
		$self->removeChild($cap) if $cap;
		return !!$cap;
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		caption => 'returns the C<< <caption> >> element (if any)',
	);

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		createCaption => 'returns the C<< <caption> >> element, creating one if there is none',
	);

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		deleteCaption => 'delete the C<< <caption> >> element (if any), and returns a boolean indicating whether anything was deleted',
	);

	foreach (qw/tHead createTHead deleteTHead tFoot createTFoot deleteTFoot
		tBodies createTBody rows insertRow deleteRow border/)
	{
		*$_ = sub { die 'TODO' };
		HTML::HTML5::DOMutil::AutoDoc->add(__PACKAGE__, $_, '@@TODO - not implemented yet');
	}
}

{	package HTML::HTML5::DOM::HTMLTableSectionElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLTableSectionElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLTableSectionElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/tbody tfoot thead/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	sub rows
	{
		my $self  = shift;
		return $self->getChildrenByTagName('*')->grep(sub { $_->tagName =~ m{^(tr)$}i });
	}

	HTML::HTML5::DOMutil::AutoDoc->add(__PACKAGE__,
		rows => 'returns a list of C<< <tr> >> child elements'
	);

	sub insertRow      { die "TODO" }
	sub deleteRow      { die "TODO" }

	HTML::HTML5::DOMutil::AutoDoc->add(__PACKAGE__, $_, '@@TODO')
		for qw/insertRow deleteRow/;
}

{	package HTML::HTML5::DOM::HTMLTableCellElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLTableCellElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLTableCellElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw//;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(
		qw/rowSpan=rowspan colSpan=colspan/
		);

	sub headers
	{
		die "TODO";
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'headers',
		'@@TODO - should return a list of C<< <th> >> elements that act as a header for this cell.',
	);

	sub cellIndex
	{
		die "TODO";
	}

	HTML::HTML5::DOMutil::AutoDoc->add(
		__PACKAGE__,
		'cellIndex',
		"\@\@TODO - should return the cell's index within its row.",
		);
}

{	package HTML::HTML5::DOM::HTMLTableDataCellElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLTableDataCellElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLTableDataCellElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/td/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLTableCellElement'];
}

{	package HTML::HTML5::DOM::HTMLTableHeaderCellElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLTableHeaderCellElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLTableHeaderCellElement::VERSION   = '0.002';
	};
		
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/th/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLTableCellElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/scope/);
}

{	package HTML::HTML5::DOM::HTMLTableRowElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLTableRowElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLTableRowElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/tr/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	sub rowIndex        { die "TODO" }
	sub sectionRowIndex { die "TODO" }
	sub insertCell      { die "TODO" }
	sub deleteCell      { die "TODO" }

	HTML::HTML5::DOMutil::AutoDoc->add(__PACKAGE__, $_, '@@TODO')
		for qw/sectionRowIndex rowIndex insertCell deleteCell/;

	sub cells
	{
		my $self  = shift;
		return $self->getChildrenByTagName('*')->grep(sub { $_->tagName =~ m{^(td|th)$}i });
	}

	HTML::HTML5::DOMutil::AutoDoc->add(__PACKAGE__,
		cells => 'returns a list of C<< <th> >> and C<< <td> >> child elements'
	);
}

{	package HTML::HTML5::DOM::HTMLTextAreaElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLTextAreaElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLTextAreaElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/textarea/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_labels_method;
	__PACKAGE__->_mk_form_methods([qw/form/]);
}

{	package HTML::HTML5::DOM::HTMLTimeElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLTimeElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLTimeElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/time/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	sub datetime
	{
		die "TODO";
	}
}

{	package HTML::HTML5::DOM::HTMLTitleElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLTitleElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLTitleElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/title/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];

	__PACKAGE__->_mk_attribute_accessors(qw/text==TEXT/);
}

{	package HTML::HTML5::DOM::HTMLTrackElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLTrackElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLTrackElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/track/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];
}

{	package HTML::HTML5::DOM::HTMLUListElement;

	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLUListElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLUListElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/ul/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLElement'];
}

{	package HTML::HTML5::DOM::HTMLVideoElement;
	
	use 5.010;
	use strict qw(vars subs);
	use mro 'c3';

	BEGIN {
		$HTML::HTML5::DOM::HTMLVideoElement::AUTHORITY = 'cpan:TOBYINK';
		$HTML::HTML5::DOM::HTMLVideoElement::VERSION   = '0.002';
	};
	
	our @ELEMENTS;
	BEGIN {
		@ELEMENTS = map { sprintf('{%s}%s', HTML::HTML5::DOM->XHTML_NS, $_) }
			qw/video/;
	}

	use XML::LibXML::Augment 0
		-names => [@ELEMENTS],
		-isa   => ['HTML::HTML5::DOM::HTMLMediaElement'];

	__PACKAGE__->_mk_attribute_accessors(
		qw/poster==URI height width/
		);
}

1;

__END__

=head1 NAME

HTML::HTML5::DOM - implementation of the HTML5 DOM on top of XML::LibXML

=head1 SYNOPSIS

 use HTML::HTML5::DOM;
 
 # Here $doc is an XML::LibXML::Document...
 my $doc = HTML::HTML5::Parser->load_html(location => 'my.html');
 
 # This upgrades it to an HTML::HTML5::DOM::HTMLDocument...
 XML::LibXML::Augment->rebless($doc);
 
 # What's the page title?
 warn $doc->getElementsByTagName('title')->get_index(1)->text;
 
 # Let's submit the first form on the page...
 my $forms = $doc->getElementsByTagName('form');
 $forms->get_index(1)->submit;

=head1 DESCRIPTION

HTML::HTML5::DOM is a layer on top of XML::LibXML which provides a number
of additional classes and methods for elements. Because it wraps almost
every XML::LibXML method, it is not as fast as using XML::LibXML directly
(which is an XS module), but it is more convenient.

=head2 DOM Support

HTML::HTML5::DOM implements those parts of the HTML5 DOM which are
convenient to do so, and also supports a lot of the pre-HTML5 DOM which
was obsoleted by the HTML5 spec. Additionally a number of DOM extensions
(methods prefixed with C<p5_>) are provided.

DOM events and event handlers (e.g. C<onclick>) are not supported, and
are unlikely to be supported in the foreseeable future.

The CSS bits of DOM are not supported, but may be in the future.

=head2 Perl specifics

DOM attributes are typically implemented as get/set/clear methods. For
example:

  warn $my_div->id;      # get
  $my_div->id($new_id);  # set
  $my_div->id(undef);    # clear

Methods which return a list usually return a normal Perl list when called
in list context, and an XML::LibXML::NodeList (or a subclass of that) when
called in list context.

Methods that return a URI generally return one blessed into the L<URI>
class.

Methods that return a datetime, generally return one blessed into the
L<DateTime> class.

Methods that result in hypertext navigation (e.g. clicking a link or
submitting a form) generally return an L<HTTP::Request> object (which
you can pass to an L<LWP::UserAgent> or L<WWW::Mechanize> instance).

The standard Perl C<isa> method is overridden to support two additional
calling styles:

  $elem->isa( 'h1' );                 # element tag name
  $elem->isa( -HTMLHeadingElement );  # DOM interface name

=head2 HTML::HTML5::DOM class methods

While most of the interesting stuff is in L<HTML::HTML5::DOM::HTMLElement>
and other classes like that, the HTML::HTML5::DOM package itself provides a
handful of methods of its own.

=over

=item * C<< XHTML_NS >>

Constant. The XHTML namespace URI as a string.

=item * C<< getDOMImplementation >>

Gets a singleton object blessed into the HTML::HTML5::DOM class.

=item * C<< hasFeature >>

Given a feature and version, returns true if the feature is supported.

  my $impl = HTML::HTML5::DOM->getDOMImplementation;
  if ($impl->hasFeature('Core', '2.0')) {
    # ... do stuff
  }

=item * C<< getFeature >>

Given a feature and version, returns an HTML::HTML5::DOMutil::Feature object.

=item * C<< registerFeature >>

Experimental method to extend HTML::HTML5::DOM.

  my $monkey = HTML::HTML5::DOMutil::Feature->new(Monkey => '1.0');
  $monkey->add_sub(
    HTMLElement => 'talk',
    sub { print "screech!\n" },
  );
  $impl->registerFeature($monkey);
  
  $element->talk if $impl->hasFeature(Monkey => '1.0');

=item * C<< parse >>

Given a file handle, file name or URL (as a string or L<URI> object),
parses the file, returning an L<HTML::HTML5::DOM::HTMLDocument> object.

This function uses HTML::HTML5::Parser but you can alternatively use
XML::LibXML's XML parser:

 my $dom = HTML::HTML5::DOM->parse($fh, using => 'libxml');

=item * C<< parseString >>

As per C<parse>, but parses a string.

=item * C<< createDocument >>

Returns an HTML::HTML5::DOM::HTMLDocument representing a blank page.

=item * C<< createDocumentType >>

Given a qualified name, public identifier (which might be undef) and system
identifier (also perhaps undef), returns a doctype tag.

This is currently returned as a string, but in an ideal world would be an
L<XML::LibXML::Dtd> object.

=back

=head1 BUGS

L<http://rt.cpan.org/Dist/Display.html?Queue=HTML-HTML5-DOM>.

=head1 SEE ALSO

L<HTML::HTML5::DOM::ReleaseNotes>.

=head2 General DOM information

B<HTML5 DOM Specifications:>
L<http://www.w3.org/TR/domcore/>,
L<http://www.w3.org/TR/html5/index.html#interfaces>.

B<Pre-HTML5 DOM Specifications:>
L<http://www.w3.org/TR/2000/REC-DOM-Level-2-Core-20001113/core.html>
L<http://www.w3.org/TR/DOM-Level-2-HTML/html.html>.

=head2 Other packages in this distribution

=over

=item * L<HTML::HTML5::DOM::HTMLAnchorElement>

=item * L<HTML::HTML5::DOM::HTMLAreaElement>

=item * L<HTML::HTML5::DOM::HTMLAudioElement>

=item * L<HTML::HTML5::DOM::HTMLBRElement>

=item * L<HTML::HTML5::DOM::HTMLBaseElement>

=item * L<HTML::HTML5::DOM::HTMLBodyElement>

=item * L<HTML::HTML5::DOM::HTMLButtonElement>

=item * L<HTML::HTML5::DOM::HTMLCanvasElement>

=item * L<HTML::HTML5::DOM::HTMLCollection>

=item * L<HTML::HTML5::DOM::HTMLCommandElement>

=item * L<HTML::HTML5::DOM::HTMLDListElement>

=item * L<HTML::HTML5::DOM::HTMLDataListElement>

=item * L<HTML::HTML5::DOM::HTMLDetailsElement>

=item * L<HTML::HTML5::DOM::HTMLDivElement>

=item * L<HTML::HTML5::DOM::HTMLDocument>

=item * L<HTML::HTML5::DOM::HTMLElement>

=item * L<HTML::HTML5::DOM::HTMLEmbedElement>

=item * L<HTML::HTML5::DOM::HTMLFieldSetElement>

=item * L<HTML::HTML5::DOM::HTMLFormControlsCollection>

=item * L<HTML::HTML5::DOM::HTMLFormElement>

=item * L<HTML::HTML5::DOM::HTMLHRElement>

=item * L<HTML::HTML5::DOM::HTMLHeadElement>

=item * L<HTML::HTML5::DOM::HTMLHeadingElement>

=item * L<HTML::HTML5::DOM::HTMLHtmlElement>

=item * L<HTML::HTML5::DOM::HTMLIFrameElement>

=item * L<HTML::HTML5::DOM::HTMLImageElement>

=item * L<HTML::HTML5::DOM::HTMLInputElement>

=item * L<HTML::HTML5::DOM::HTMLKeygenElement>

=item * L<HTML::HTML5::DOM::HTMLLIElement>

=item * L<HTML::HTML5::DOM::HTMLLabelElement>

=item * L<HTML::HTML5::DOM::HTMLLegendElement>

=item * L<HTML::HTML5::DOM::HTMLLinkElement>

=item * L<HTML::HTML5::DOM::HTMLMapElement>

=item * L<HTML::HTML5::DOM::HTMLMediaElement>

=item * L<HTML::HTML5::DOM::HTMLMenuElement>

=item * L<HTML::HTML5::DOM::HTMLMetaElement>

=item * L<HTML::HTML5::DOM::HTMLMeterElement>

=item * L<HTML::HTML5::DOM::HTMLModElement>

=item * L<HTML::HTML5::DOM::HTMLOListElement>

=item * L<HTML::HTML5::DOM::HTMLObjectElement>

=item * L<HTML::HTML5::DOM::HTMLOptGroupElement>

=item * L<HTML::HTML5::DOM::HTMLOptionElement>

=item * L<HTML::HTML5::DOM::HTMLOutputElement>

=item * L<HTML::HTML5::DOM::HTMLParagraphElement>

=item * L<HTML::HTML5::DOM::HTMLParamElement>

=item * L<HTML::HTML5::DOM::HTMLPreElement>

=item * L<HTML::HTML5::DOM::HTMLProgressElement>

=item * L<HTML::HTML5::DOM::HTMLQuoteElement>

=item * L<HTML::HTML5::DOM::HTMLScriptElement>

=item * L<HTML::HTML5::DOM::HTMLSelectElement>

=item * L<HTML::HTML5::DOM::HTMLSourceElement>

=item * L<HTML::HTML5::DOM::HTMLSpanElement>

=item * L<HTML::HTML5::DOM::HTMLStyleElement>

=item * L<HTML::HTML5::DOM::HTMLTableCaptionElement>

=item * L<HTML::HTML5::DOM::HTMLTableCellElement>

=item * L<HTML::HTML5::DOM::HTMLTableColElement>

=item * L<HTML::HTML5::DOM::HTMLTableDataCellElement>

=item * L<HTML::HTML5::DOM::HTMLTableElement>

=item * L<HTML::HTML5::DOM::HTMLTableHeaderCellElement>

=item * L<HTML::HTML5::DOM::HTMLTableRowElement>

=item * L<HTML::HTML5::DOM::HTMLTableSectionElement>

=item * L<HTML::HTML5::DOM::HTMLTextAreaElement>

=item * L<HTML::HTML5::DOM::HTMLTimeElement>

=item * L<HTML::HTML5::DOM::HTMLTitleElement>

=item * L<HTML::HTML5::DOM::HTMLTrackElement>

=item * L<HTML::HTML5::DOM::HTMLUListElement>

=item * L<HTML::HTML5::DOM::HTMLVideoElement>

=item * L<HTML::HTML5::DOM::RadioNodeList>

=back

=head2 Packages external to this distribution

B<"Friends":>
L<XML::LibXML>,
L<XML::LibXML::Augment>,
L<HTML::HTML5::Parser>,
L<HTML::HTML5::Writer>,
L<HTML::HTML5::ToText>,
L<HTML::HTML5::Builder>.

B<"Rivals":>
L<HTML::DOM>,
L<HTML::Tree>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

