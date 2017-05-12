package HTML::Microformats::Mixin::Parser;

use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Utilities qw(/^search/);
use HTML::Microformats::Format::adr;
use HTML::Microformats::Datatype;
use HTML::Microformats::Format::geo;
use HTML::Microformats::Format::hAtom;
use HTML::Microformats::Format::hCalendar;
use HTML::Microformats::Format::hCard;
use HTML::Microformats::Format::hMeasure;
use HTML::Microformats::Format::RelEnclosure;
use HTML::Microformats::Format::RelLicense;
use HTML::Microformats::Format::RelTag;
use HTML::Microformats::Format::species;
use URI::URL;
use XML::LibXML qw(:all);

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Mixin::Parser::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Mixin::Parser::VERSION   = '0.105';
}

# Cleans away nested compound microformats. Any intentionally
# nested microformats (e.g. vcard class="agent vcard") should be
# dealt with BEFORE calling the destroyer! Because of the
# destructive nature of this function, make sure that you only
# use it on a clone of the real node.
sub _destroyer
{
	my $self = shift;
	my $element = shift;
	
	# Classes to be destroyed
	my @containers = qw(mfo vcard adr geo vcalendar vevent vtodo valarm
		vfreebusy hfeed hentry hslice hreview hresume xfolkentry biota haudio
		hmeasure hangle hmoney hlisting vtodo-list figure hproduct hnews);
	my %C;
	foreach my $c (@containers) { $C{$c}=1; }
	
	# Some classes may be retained, optionally.
	foreach my $c (@_)          { $C{$c}=0; }

	# Assemble them all into the regular expression of death.
	@containers = ();
	foreach my $c (keys %C) { push @containers, $c if $C{$c}; }
	my $regexp = join '|', @containers;
	$regexp = "\\b($regexp)\\b";
	$regexp =~ s/\-/\\\-/g;
	
	# Destroy child elements matching the regular expression.
	foreach my $e ($element->getElementsByTagName('*'))
	{	
		next if $e == $element;
		
		if ($e->getAttribute('class') =~ /$regexp/)
		{
			$self->_destroy_element($e);
			my $newclass = $e->getAttribute('class');
			$newclass =~ s/$regexp//g;
			$e->setAttribute('class', $newclass);
			$e->removeAttribute('class') unless length $newclass;
		}
	}
}

sub _destroy_element
{
	my $self    = shift;
	my $element = shift;
	
	foreach my $c ($element->getElementsByTagName('*'))
	{
		$c->removeAttribute('class');
		$c->removeAttribute('rel');
		$c->removeAttribute('rev');
	}
}

sub _expand_patterns
{
	my $self = shift;
	my $root = shift || $self->element;
	my $max_include_loops = shift || 2;

	# Expand microformat include pattern.
	my $incl_iterations = 0;
	my $replacements = 1;
	while (($incl_iterations < $max_include_loops) && $replacements)
	{
		$replacements = $self->_expand_include_pattern($root) + $self->_expand_include_pattern_2($root);
		$incl_iterations++;
	}
	
	# Table cell headers pattern.
	$self->_expand_table_header_pattern($root);	

	# Magical data-X class pattern.
	$self->_expand_dataX_class_pattern($root);	
}

sub _expand_dataX_class_pattern
{
	my $self = shift;
	my $node = shift;

	return
		unless $self->context->has_profile('http://purl.org/uF/pattern-data-class/1');
		
	foreach my $kid ($node->getElementsByTagName('*'))
	{
		my $classes = $kid->getAttribute('class');
		$classes =~ s/(^\s+|\s+$)//g;
		$classes =~ s/\s+/ /g;
		my @classes = split / /, $classes;
		map s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg, @classes;
		my @dataClasses = grep /^data\-/, @classes;
		next unless (@dataClasses);
		
		my $val = '';
		foreach my $d (@dataClasses)
		{
			$val = $d unless ((length $val) > (length $d));
		}
		
		$val =~ s/^data\-//;
		$kid->setAttribute('data-cpan-html-microformats-content', $val);
	}
}

sub _expand_table_header_pattern
{
	my $self = shift;
	my $node = shift;
	
	# Add node itself to list!
	my @elements = $node->getElementsByTagName('td');
	if (('XML::LibXML::Element' eq ref $node) && $node->tagName =~ /^t[dh]$/i)
		{ unshift @elements, $node; }
		
	foreach my $tag (@elements)
	{
		next unless length $tag->getAttribute('headers');
		
		my $headers = $tag->getAttribute('headers');
		$headers =~ s/(^\s+|\s+$)//g;
		$headers =~ s/\s+/ /g;
		my @headers = split / /, $headers;
		
		foreach my $H (@headers)
		{
			my $Htag = searchID($H, $self->context->document);
			next unless ($Htag);
			next unless ($Htag->tagName =~ /^t[dh]$/i);
			
			my $new = $self->context->document->createElement('div');
			$new->setAttribute('class', $Htag->getAttribute('class'));
			foreach my $kid ($Htag->childNodes)
			{
				my $x = $kid->cloneNode(1);
				if ($kid->nodeType==XML_ELEMENT_NODE || $kid->nodeType==XML_TEXT_NODE)
				{
					my $r = $new->appendChild($x);
				}
			}
			$tag->appendChild($new);
		}
		
		$tag->setAttribute('headers', '');
	}
}

sub _expand_include_pattern
# Implements the standard microformats include pattern.
{
	my $self  = shift;
	my $node  = shift;
	my $class = shift || 'include';
	my $rv = 0;
	
	# For each link...
	my @links1 = $node->getElementsByTagName('a');
	my @links2 = $node->getElementsByTagName('object');
	my @links3 = $node->getElementsByTagName('area');
	my @links = (@links1, @links2, @links3);
	
	foreach my $link (@links)
	{	
		# Skip pattern if no class attribute found.
		my $classList = $link->getAttribute('class') || next;
		
		# We've found a use of the include pattern
		if ($classList =~ / (^|\s) $class (\s|$) /x)
		{
			my $href = $link->hasAttribute('href') ?
				$link->getAttribute('href') :
				$link->getAttribute('data') ;
				
			my $id = undef;
			if ($href =~ /^\#(.*)$/)
			{
				$id = $1;
			}
			else
			{
				next;
			}

			# find the included node
			my $replacement = searchID($id, $self->context->document);
			next unless $replacement;

			# do not include it if it's an ancestor
			my $link_xpath = $link->getAttribute('data-cpan-html-microformats');
			my $repl_xpath = $replacement->getAttribute('data-cpan-html-microformats');
			next if (substr($link_xpath, 0, length $repl_xpath) eq $repl_xpath);

			# replace the including element with the included element
			$replacement = $replacement->cloneNode(1);
			$link->getParentNode->replaceChild($replacement, $link) && $rv++;
		}
	}
	
	# Return number of replacements made.
	return $rv;
	
}

sub _expand_include_pattern_2
# Implements the alternative microformats include pattern.
{
	my $self  = shift;
	my $node  = shift;
	my $classpfx = shift || '#';
	my $rv = 0;
	
	# Add node itself to list!
	my @elements = $node->getElementsByTagName('*');
	unshift @elements, $node;
	
	# For each element...
	foreach my $elem (@elements)
	{
		# Skip pattern if no class attribute found.
		my $classList;
		$classList = $elem->getAttribute('class')
			if 'XML::LibXML::Element' eq ref $elem;
		next unless ($classList =~ / $classpfx /x);

		my $atEnd = 0;
		
		$classList =~ s/(^\s|\s$)//g;
		$classList =~ s/\s+/ /g;
		my @classes = split / /, $classList;
		my @newClassList = ();
		
		foreach my $c (@classes)
		{
			if (substr($c,0,1) ne $classpfx && length($c)>=1)
			{
				push @newClassList, $c;
				$atEnd = 1;
				next;
			}
			
			my $id = $c; $id =~ s/^\#//x;
			my $replacement = searchID($id, $self->context->document) || next;

			# do not include it if it's an ancestor
			my $link_xpath = $elem->getAttribute('data-cpan-html-microformats');
			my $repl_xpath = $replacement->getAttribute('data-cpan-html-microformats');
			next if (substr($link_xpath, 0, length $repl_xpath) eq $repl_xpath);

			$replacement = $replacement->cloneNode(1);
			if ($atEnd)
			{
				$elem->appendChild($replacement) && $rv++;
			}
			else
			{
				$elem->insertBefore($replacement, $elem->getFirstChild) && $rv++;
			}
		}
		
		$elem->setAttribute('class', join(' ', @newClassList))
			if 'XML::LibXML::Element' eq ref $elem;
	}
	
	# Return number of replacements made.
	return $rv;
}

sub _matching_nodes
{
	my $self  = shift;
	my $class = shift;
	my $type  = shift;
	my $root  = shift || $self->element;
	my @matching_nodes;
	
	if ($type =~ /r/i)
		{ @matching_nodes = searchRel($class, $root); }
	elsif ($type =~ /t/i)
		{ @matching_nodes = $root->getElementsByTagName($class); }
	
	if ($type !~ /[rt]/)
	{
		my @mn2 = searchClass($class, $root);
		push @matching_nodes, @mn2;
	}
	
	return @matching_nodes;
}

sub _simple_parse_found_error
{
	my $self = shift;
	push @{ $self->{ERRORS} }, \@_;
}

#  1  = singular, required
#  ?  = singular, optional
#  +  = plural, required
#  *  = plural, optional
#  ** = plural, optional, and funny behaviour with embedded microformats
#  d  = date
#  D  = duration
#  e  = exrule/rrule
#  i  = interval
#  h  = HTML
#  H  = HTML and Text (HTML value is prefixed 'html_')
#  m  = embedded composite microformat
#  M  = embedded composite microformat or text
#  MM = embedded composite microformat or text, if url use pseudo-microformat
#  n  = numeric
#  r  = rel, not class
#  R  = rel *or* class
#  t  = tag name, not class
#  T  = tag name *or* class
#  u  = URI
#  U  = URI or fragment or text
#  &  = concatenate strings
#  <  = Also store node (in $self->{'DATA_'})
#  #  = _simple_parse should ignore this property
#  v  = don't do 'value' excerption

sub _simple_parse
# This was not simple to implement, but should be simple to use.
# This function takes on too much responsibility.
# It should delegate stuff.
{
	my $self    = shift;
	my $root    = shift || $self->element;
	my $classes = $self->format_signature->{'classes'};
	my $options = $self->format_signature->{'options'} || {};
	my $page    = $self->context;
	
	# So far haven't needed any more than this.
	my $uf_roots = {
		'hCard'     => 'vcard',
		'hEvent'    => 'vevent',
		'hAlarm'    => 'valarm',
		'hTodo'     => 'vtodo',
		'hFreebusy' => 'vfreebusy',
		'hCalendar' => 'vcalendar',
		'hMeasure'  => 'hmeasure|hangle|hmoney',
		'species'   => 'biota',
		'hAtom'     => 'hfeed'
	};
	
	# Derived from HTML::Tagset, but some modifications to the order of attrs.
	my $link_elements = {
		'a'       => ['href'],
		'applet'  => ['codebase', 'archive', 'code'],
		'area'    => ['href'],
		'base'    => ['href'],
		'bgsound' => ['src'],
		'blockquote' => ['cite'],
#		'body'    => ['background'],
		'del'     => ['cite'],
		'embed'   => ['src', 'pluginspage'],
		'form'    => ['action'],
		'frame'   => ['src', 'longdesc'],
		'iframe'  => ['src', 'longdesc'],
#		'ilayer'  => ['background'],
		'img'     => ['src', 'lowsrc', 'longdesc', 'usemap'],
		'input'   => ['src', 'usemap'],
		'ins'     => ['cite'],
		'isindex' => ['action'],
		'head'    => ['profile'],
		'layer'   => ['src'], # 'background'
		'link'    => ['href'],
		'object'  => ['data', 'classid', 'codebase', 'archive', 'usemap'],
		'q'       => ['cite'],
		'script'  => ['src', 'for'],
#		'table'   => ['background'],
#		'td'      => ['background'],
#		'th'      => ['background'],
#		'tr'      => ['background'],
		'xmp'     => ['href'],
	};
	
	foreach my $c (@$classes)
	{
		my $class         = $c->[0];
		my $type          = $c->[1];
		my $class_options = $c->[2] || {};
		my @try_ufs       = split / /, $class_options->{'embedded'};
		
		next if $type =~ /#/;
		
		next unless $type =~ /m/i && defined $try_ufs[0];
		
		my @parsed_objects;
		my @matching_nodes = $self->_matching_nodes($class, $type, $root);
		my @ok_matching_nodes;
		
		if ($class_options->{'nesting-ok'})
		{
			@ok_matching_nodes = @matching_nodes;
		}
		else
		{
			# This is a little bit of extra code that checks for interleaving uF
			# root class elements and excludes them. For example, in the following,
			# the outer hCard should not have an agent:
			# <div class="vcard">
			#  <p class="birth vcard">
			#   <span class="agent vcard"></span>
			#  </p>
			# </div>
			my @mfos = qw(mfo vcard adr geo vcalendar vevent vtodo valarm
				vfreebusy hfeed hentry hslice hreview hresume xfolkentry biota haudio
				hmeasure hangle hmoney hlisting vtodo-list figure hproduct hnews);
			my $mfos = '\b('.(join '|', @mfos).')\b';
			foreach my $u (@{$class_options->{'allow-interleaved'}})
				{ $mfos =~ s/\|$u//; }

			foreach my $mn (@matching_nodes)
			{
				my $is_ok = 1;
				my $ancestor = $mn->parentNode;
				while (length $ancestor->getAttribute('data-cpan-html-microformats-nodepath') > length $root->getAttribute('data-cpan-html-microformats-nodepath'))
				{
					if ($ancestor->getAttribute('class')=~$mfos)
					{
						$is_ok = 0;
						last;
					}
					$ancestor = $ancestor->parentNode;
				}
				push @ok_matching_nodes, $mn if ($is_ok);
			}
		}
		
		# For each matching node
		foreach my $node (@ok_matching_nodes)
		{
			my @node_parsed_objects;
			
			# Try each microformat until we find something
			no strict 'refs';
			foreach my $uf (@try_ufs)
			{				
				my $uf_class = (defined $uf_roots->{$uf}) ? $uf_roots->{$uf} : lc($uf);
				last if defined $node_parsed_objects[0];
				
				if ($uf eq '!person')
				{
					# This is used as a last-ditch attempt to parse a person.
					my $obj = HTML::Microformats::Format::hCard->new_fallback($node, $self->context);
					push @node_parsed_objects, $obj;
				}
				elsif ($node->getAttribute('class') =~ /\b($uf_class)\b/)
				{
					my $pkg = 'HTML::Microformats::Format::'.$uf;
					my $obj = eval "${pkg}->new(\$node, \$self->context, in_hcalendar => \$class_options->{'is-in-cal'});";
					push @node_parsed_objects, $obj;
				}
				else
				{
					my $pkg = 'HTML::Microformats::Format::'.$uf;
					my @all = eval "${pkg}->extract_all(\$node, \$self->context, in_hcalendar => \$class_options->{'is-in-cal'});";
					push @node_parsed_objects, @all if @all;
				}
				
				$self->_simple_parse_found_error('W', "Multiple embedded $uf objects found in a single $class property. This is weird.")
					if defined $node_parsed_objects[1];
			}
			use strict 'refs';
			
			# If we've found something
			if (defined $node_parsed_objects[0] && ref $node_parsed_objects[0])
			{
				unless ($class_options->{'again-again'})
				{
					# Remove $class from $node's class list, lest we pick it up again
					# in the next giant loop!
					my $new_class_attr = $node->getAttribute('class');
					$new_class_attr =~ s/\b($class)\b//;
					$node->setAttribute('class', $new_class_attr);
					$node->removeAttribute('class') unless $new_class_attr;
				}

				# If $type contains '**' then allow
				# <div class="agent">
				#   <p class="vcard"></p>
				#   <p class="vcard"></p>
				# </div>
				foreach my $p (@node_parsed_objects)
				{
					next unless ref $p;
					# Record parent property node in case we need it (hResume does)!
					$p->{'parent_property_node'} = $node;		
					push @parsed_objects, $p;
					last unless $type =~ /\*\*/;
				}
			}
		}
		
		# What key should we use to store everything in $self?
		my $object_key = $class;
		$object_key = $class_options->{'use-key'}
			if defined $class_options->{'use-key'};

		# Actually do the storing!
		if ($type =~ /[1\?]/ && !defined $self->{'DATA'}->{$object_key})
		{
			$self->{'DATA'}->{$object_key}  = $parsed_objects[0]
				if @parsed_objects;
			$self->{'DATA_'}->{$object_key} = $parsed_objects[0]->{'parent_property_node'}
				if @parsed_objects && $type =~ /\</;
				
			$self->_simple_parse_found_error('W', "$class is singular, but multiple instances found. Only the first one will be used.")
				if defined $parsed_objects[1];
		}
		else
		{
			foreach my $value (@parsed_objects)
			{
				push @{ $self->{'DATA'}->{$object_key} }, $value;
				push @{ $self->{'DATA_'}->{$object_key} }, $parsed_objects[0]->{'parent_property_node'}
					if $type =~ /\</;
			}
		}
	}
	
	# Destroy nested microformats.
	$self->_destroyer($root, 'hmeasure', 'hangle', 'hmoney', @{ $options->{'no-destroy'} });

	# hmeasure, and destroy each, unless saved by $options->{'no-destroy'}!
	my $do_destroy = {
		'hmeasure' => 1,
		'hangle'   => 1,
		'hmoney'   => 1
	};
	foreach my $root (@{ $options->{'no-destroy'} })
		{ $do_destroy->{$root} = 0; }

	# embedded hmeasure
	if (defined $options->{'hmeasure'})
	{
		my @measures = HTML::Microformats::Format::hMeasure->extract_all($root, $self->context);
		foreach my $m (@measures)
		{
			push @{ $self->{$options->{'hmeasure'}} }, $m
				unless defined $m->data->{'item'}
				|| defined $m->data->{'item_link'}
				|| defined $m->data->{'item_label'};
			$self->destroy_element($m->{'element'})
				if $do_destroy->{ $m->data->{'class'} } && defined $m->{'element'};
		}
	}
	
	# embedded rel-tag
	if (defined $options->{'rel-tag'})
	{
		my $key  = $options->{'rel-tag'};
		my @tags = HTML::Microformats::Format::RelTag->extract_all($root, $self->context);
		push @{ $self->{'DATA'}->{$key} }, @tags if @tags;
	}

	# embedded rel-license
	if (defined $options->{'rel-license'})
	{
		my $key  = $options->{'rel-license'};
		my @licences = HTML::Microformats::Format::RelLicense->extract_all($root, $self->context);
		push @{ $self->{'DATA'}->{$key} }, @licences if @licences;
	}

	# embedded rel-enclosure
	if (defined $options->{'rel-enclosure'})
	{
		my $key  = $options->{'rel-enclosure'};
		my @encs = HTML::Microformats::Format::RelEnclosure->extract_all($root, $self->context);
		push @{ $self->{'DATA'}->{$key} }, @encs if @encs;
	}
	
	# For each of the classes that we're looking for...
	foreach my $c (@$classes)
	{
		my $class         = $c->[0];
		my $type          = $c->[1];
		my $class_options = $c->[2] || {};
		
		# We've already processed embedded microformats.
		next if $type =~ /m/;
		
		# These properties are too complex for _simple_parse.
		next if $type =~ /#/;

		my @matching_nodes = $self->_matching_nodes($class, $type, $root);

		# Parse each node that matched.
		my @parsed_values;
		my @parsed_values_nodes;
		my @parsed_values_alternatives;
		foreach my $node (@matching_nodes)
		{
			# Jump out of the loop if we were only expecting a single value and
			# have already found it!
			if ($type =~ /[1\?]/ && defined $parsed_values[0])
			{
				$self->_simple_parse_found_error('W', "$class is singular, but multiple instances found. Only the first one will be used.");
				last;
			}
			
			# Avoid conflicts between rel=tag and class=category.
			next
				if (($class eq $options->{'rel-tag'})
				&&  ($node->getAttribute('rel') =~ /\b(tag)\b/i));

			# Ditto rel=license and class=license.
			next
				if (($class eq $options->{'rel-license'})
				&&  ($node->getAttribute('rel') =~ /\b(license)\b/i));

			# Ditto rel=enclosure and class=attach.
			next
				if (($class eq $options->{'rel-enclosure'})
				&&  ($node->getAttribute('rel') =~ /\b(enclosure)\b/i));
			
			# Parse URL types
			my ($u, $u_element);
			if ($type =~ /(u|U|MM)/)
			{
				my @value_elements;
				@value_elements = searchClass('value', $node)
					unless $type=~/v/;
				unshift @value_elements, $node;
				ELEMENT: foreach my $v (@value_elements)
				{
					if (defined $link_elements->{lc $v->tagName})
					{
						ATTR: foreach my $attr (@{ $link_elements->{lc $v->tagName} })
						{
							if (length $v->getAttribute($attr))
							{
								$u = $v->getAttribute($attr);
								$u_element = $v;
								last ELEMENT;
							}
						}
					}
					if ($type =~ /U/ && length $v->getAttribute('id'))
					{
						$u = '#'.$v->getAttribute('id');
						$u_element = $v;
						last ELEMENT;
					}
				}

				if (defined $u)
				{
					if ($type =~ /MM/)
					{
						##TODO: post-0.001
						die "Not implemented!";
						# my $px = { uri => $page->uri($u) };
						# bless $px, "Swignition::uF::Pseudo";
						# push @parsed_values, $px;
					}
					else
					{
						push @parsed_values, $page->uri($u);
					}
					push @parsed_values_nodes, $node;
					if (length $options->{'rel-me'} && $u_element->getAttribute('rel') =~ /\b(me)\b/i)
						{ $self->{'DATA'}->{$options->{'rel-me'}}++; }
					next;
				}
				else
				{
					push @parsed_values, $self->_stringify($node, 
						{
							'excerpt-class' => ($type=~/v/?undef:'value'),
							'value-title'   => defined $class_options->{'value-title'} ? $class_options->{'value-title'} : (($type=~/[Ddei]/ && $type!~/v/) ? 'allow' : undef),
							'abbr-pattern'  => 1,
						});
					push @parsed_values_nodes, $node;
					next;
				}
			}							
			
			# Extract text (and if needed, XML) string from node.
			if ($type =~ /H/)
			{
				push @parsed_values, $self->_stringify($node, ($type=~/v/?undef:'value'));
				push @parsed_values_alternatives, $self->_xml_stringify($node, undef, $class_options->{'include-self'});
				push @parsed_values_nodes, $node;
			}
			elsif ($type =~ /h/)
			{
				push @parsed_values, $self->_xml_stringify($node, undef, $class_options->{'include-self'});
				push @parsed_values_nodes, $node;
			}
			elsif ($type =~ /d/)
			{
				push @parsed_values, $self->_stringify($node, {
					'value-title'   => defined $class_options->{'value-title'} ? $class_options->{'value-title'} : (($type=~/[Ddei]/ && $type!~/v/) ? 'allow' : undef),
					'excerpt-class' => ($type=~/v/?undef:'value'),
					'abbr-pattern'  => 1,
					'datetime'      => 1,
					'joiner'        => ' ',
					'datetime-feedthrough' => defined $class_options->{'datetime-feedthrough'} ? $self->{'DATA'}->{ $class_options->{'datetime-feedthrough'} } : undef,
				});
				push @parsed_values_nodes, $node;
			}
			elsif ($type =~ /u/)
			{
				push @parsed_values, $page->uri($self->_stringify($node, ($type=~/v/?undef:'value')));
				push @parsed_values_nodes, $node;
			}
			else
			{
				push @parsed_values, $self->_stringify($node, {
						'excerpt-class' => ($type=~/v/?undef:'value'),
						'value-title'   => defined $class_options->{'value-title'} ? $class_options->{'value-title'} : (($type=~/[Ddei]/ && $type!~/v/) ? 'allow' : undef),
						'abbr-pattern'  => 1,
					});
				push @parsed_values_nodes, $node;
			}

		}
		
		# Now we have parsed values in @parsed_values. Sometimes these need to be
		# concatenated.
		if ($type =~ /\&/)
		{
			my $joiner = ($type =~ /u/i) ? ' ' : '';
			$joiner = $class_options->{'concatenate-with'}
				if defined $class_options->{'concatenate-with'};
			
			if (@parsed_values)
			{
				my $value = join $joiner, @parsed_values;
				@parsed_values = ($value);
			}
			if (@parsed_values_alternatives)
			{
				my $value = join $joiner, @parsed_values_alternatives;
				@parsed_values_alternatives = ($value);
			}
		}
		
		# Check which values are acceptable.
		my @acceptable_values;
		my @acceptable_values_nodes;
		for (my $i=0; defined $parsed_values[$i]; $i++)
		{
			my $value = $parsed_values[$i];
		
			# Check date values are OK
			if ($type =~ /d/)
			{
				$value = HTML::Microformats::Datatype::DateTime->parse($value);
				if ($value)
				{
					if ($parsed_values_nodes[$i]->getAttribute('class') =~ /\b(approx)\b/)
					{
						$value->{datatype} = 'http://dbpedia.org/resource/Approximation';
					}
					else
					{
						my @approx = searchClass('approx', $parsed_values_nodes[$i]);
						$value->{datatype} = 'http://dbpedia.org/resource/Approximation'
							if @approx;
					}
				
					push @acceptable_values, $value;
					push @acceptable_values_nodes, $parsed_values_nodes[$i];
					next;
				}
			}
			# Check durations are OK
			elsif ($type =~ /D/)
			{
				my $D = undef;
				if (HTML::Microformats::Datatype::String::isms($value))
				{
					$D = HTML::Microformats::Datatype::Duration->parse($value->{string}, $value->{dom}, $page)
				}
				else
				{
					$D = HTML::Microformats::Datatype::Duration->parse($value, undef, $page)
				}
				if (defined $D)
				{
					push @acceptable_values, $D;
					push @acceptable_values_nodes, $parsed_values_nodes[$i];
				}
				else
				{
					$self->_simple_parse_found_error('E', "$class could not be parsed as a duration.");
				}
				next;
			}
			# Check intervals are OK
			elsif ($type =~ /i/)
			{
				my $D;
				if (HTML::Microformats::Datatype::String::isms($value))
				{
					$D = HTML::Microformats::Datatype::Interval->parse($value->{string}, $value->{dom}, $page)
				}
				else
				{
					$D = HTML::Microformats::Datatype::Interval->parse($value, undef, $page)
				}
				if ($D)
				{
					push @acceptable_values, $D;
					push @acceptable_values_nodes, $parsed_values_nodes[$i];
				}
				else
				{
					$self->_simple_parse_found_error('E', "$class could not be parsed as an interval.");
				}
				next;
			}
			# Check intervals are OK
			elsif ($type =~ /e/)
			{
				my $D;
				if (HTML::Microformats::Datatype::String::isms($value))
				{
					$D = HTML::Microformats::Datatype::RecurringDateTime->parse($value->{string}, $value->{dom}, $page)
				}
				else
				{
					$D = HTML::Microformats::Datatype::RecurringDateTime->parse($value, undef, $page)
				}
				if ($D)
				{
					push @acceptable_values, $D;
					push @acceptable_values_nodes, $parsed_values_nodes[$i];
				}
				else
				{
					$self->_simple_parse_found_error('E', "$class could not be parsed as an interval.");
				}
				next;
			}
			# Everything else we won't bother to check if it's OK.
			else
			{
				push @acceptable_values, $value;
				push @acceptable_values_nodes, $parsed_values_nodes[$i];
				next;
			}
		}
		
		# What key should we use to store everything in $self?
		my $object_key = $class;
		$object_key = $class_options->{'use-key'}
			if (defined $class_options->{'use-key'});
		
		# Actually do the storing!
		if ($type =~ /[1\?\&]/ && !defined $self->{$object_key})
		{
			$self->{'DATA'}->{$object_key}  = $acceptable_values[0]
				if @acceptable_values;
			$self->{'DATA_'}->{$object_key} = $acceptable_values_nodes[0]
				if @acceptable_values && $type =~ /\</;
		}
		else
		{
			for (my $i=0; defined $acceptable_values[$i]; $i++)
			{
				push @{ $self->{'DATA'}->{$object_key} }, $acceptable_values[$i];
				push @{ $self->{'DATA_'}->{$object_key} }, $acceptable_values_nodes[$i]
					if ($type =~ /\</);	
			}
		}
		
		if ($type =~ /[1\+]/ && !defined $self->{$object_key})
		{
			$self->_simple_parse_found_error('E', "$class is required, but no acceptable value was found.");
		}

		# Store HTML values too!
		if ($type =~ /H/)
		{
			if ($type =~ /[1\?\&]/ && defined $parsed_values_alternatives[0])
			{
				$self->{'DATA'}->{'html_'.$object_key} = $parsed_values_alternatives[0];
			}
			else
			{
				foreach my $value (@parsed_values_alternatives)
				{
					push @{ $self->{'DATA'}->{'html_'.$object_key} }, $value;
				}
			}
		}
		
		# for classes called 'uid', special handling.
		if ($class eq 'uid' and !defined $self->{'DATA'}->{$object_key})
		{
			if ($root->hasAttribute('id') and length $root->getAttribute('id'))
			{
				$self->{'DATA'}->{$object_key} = $self->context->uri('#'.$root->getAttribute('id'));
			}
		}
	}
}

sub _stringify
{
	my $self = shift;
	return HTML::Microformats::Utilities::stringify(@_);
}

sub _xml_stringify
{
	my $self = shift;
	return HTML::Microformats::Utilities::xml_stringify(@_);
}

1;

__END__

=head1 NAME

HTML::Microformats::Mixin::Parser - microformat parsing mixin

=head1 DESCRIPTION

HTML::Microformats::Mixin::Parser implements a number of private methods that
take care of the bulk of parsing complex, compound microformats.

Many of the individual microformat modules multi-inherit from this.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats>

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut
