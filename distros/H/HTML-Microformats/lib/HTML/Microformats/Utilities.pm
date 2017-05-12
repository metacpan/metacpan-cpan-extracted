=head1 NAME

HTML::Microformats::Utilities - utility functions for searching and manipulating HTML

=head1 DESCRIPTION

This module includes a few functions for searching and manipulating HTML trees.

=cut

package HTML::Microformats::Utilities;

use base qw(Exporter);
use strict qw(subs vars); no warnings;
use utf8;
use 5.010;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Utilities::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Utilities::VERSION   = '0.105';
}
our @EXPORT_OK;
BEGIN {
	@EXPORT_OK = qw(searchClass searchAncestorClass searchRel searchRev searchID searchAncestorTag stringify xml_stringify);
}

use HTML::Microformats::Datatype::String;
use XML::LibXML qw(:all);


=over 4

=item C<< searchClass($class, $node, [$prefix]) >>

Returns a list of elements which are descendents of $node and have class name $class.

$class can be a plain string, or a regular expression.

If $prefix is supplied it is used as an optional prefix for $class. For example, with $class 'bar'
and $prefix 'foo', searchClass will look for all of the following classes: 'bar', 'foobar', 'foo-bar'
and 'foo:bar'.

=cut

sub searchClass
{
	my $target = shift;
	my $dom    = shift;
	my $prefix = shift || undef;
	
	my @matches;
	return @matches unless $dom;
	
	foreach my $node ($dom->getElementsByTagName('*'))
	{
		my $classList;
		$classList = $node->getAttribute('class');
		$classList = $node->getAttribute('name')
			if (!length $classList) && ($node->tagName eq 'param');
		
		next unless length $classList;
		
		if ((defined $prefix) && $classList =~ / (^|\s) ($prefix [:\-]?)? $target (\s|$) /x)
		{
			push @matches, $node;
		}
		elsif ($classList =~ / (^|\s) $target (\s|$) /x)
		{
			push @matches, $node;
		}
	}
	
	return @matches;	
}

=item C<< searchAncestorClass($class, $node, [$skip]) >>

Returns the first element which is an ancestor of $node having class name $class.

$class can be a plain string, or a regular expression.

$skip is the number of levels of ancestor to skip. If $skip is 0, then potentially searchAncestorClass
will return $node itself. If $skip is 1, then it will not return $node but could potentially return
its parent, and so on.

=cut

sub searchAncestorClass
{
	my $target = shift;
	my $dom    = shift;
	my $skip   = shift;
	
	return undef unless defined $dom;

	if (!defined $skip or $skip <= 0)
	{
		my $classList;
		$classList = $dom->getAttribute('class');
		$classList = $dom->getAttribute('name')
			if (!length $classList and $dom->tagName eq 'param');
		
		if ($classList =~ / (^|\s) $target (\s|$) /x)
		{
			return $dom;
		}
	}
	
	if (defined $dom->parentNode
	and $dom->parentNode->isa('XML::LibXML::Element'))
	{
		return searchAncestorClass($target, $dom->parentNode, $skip-1);
	}
	
	return undef;
}

=item C<< searchRel($relationship, $node) >>

Returns a list of elements which are descendents of $node and have relationship $relationship.

$relationship can be a plain string, or a regular expression.

=cut

sub searchRel
{
	my $target = shift;
	my $dom    = shift;
	
	$target =~ tr/[\:\.]/\[\:\.\]/ unless ref $target;
	
	my @matches = ();
	for my $node ($dom->getElementsByTagName('*'))
	{
		my $classList = $node->getAttribute('rel');
		next unless length $classList;
		
		if ($classList =~ / (^|\s) $target (\s|$) /ix)
		{
			push @matches, $node;
		}
	}
	
	return @matches;
}

=item C<< searchRev($relationship, $node) >>

As per searchRel, but uses the rev attribute.

=cut

sub searchRev
{
	my $target = shift;
	my $dom    = shift;
	
	$target =~ tr/[\:\.]/\[\:\.\]/ unless ref $target;
	
	my @matches = ();
	for my $node ($dom->getElementsByTagName('*'))
	{
		my $classList = $node->getAttribute('rev');
		next unless length $classList;
		
		if ($classList =~ / (^|\s) $target (\s|$) /ix)
		{
			push @matches, $node;
		}
	}
	
	return @matches;
}

=item C<< searchID($id, $node) >>

Returns a descendent of $node with id attribute $id, or undef.

=cut

sub searchID
{
	my $target = shift;
	my $dom    = shift;
	
	$target =~ s/^\#//;
	
	for my $node ($dom->getElementsByTagName('*'))
	{
		my $id   = $node->getAttribute('id') || next;
		return $node if $id eq $target;
	}	
}

=item C<< searchAncestorTag($tagname, $node) >>

Returns the nearest ancestor of $node with tag name $tagname, or undef.

=cut

sub searchAncestorTag
{
	my ($target, $node) = @_;
	
	return $node
		if $node->localname =~ /^ $target $/ix;
		
	return searchAncestorTag($target, $node->parentNode)
		if defined $node->parentNode
		&& $node->parentNode->nodeType == XML_ELEMENT_NODE;
	
	return undef;
}

=item C<< stringify($node, \%options) >>

Returns a stringified version of a DOM element. This is conceptually equivalent
to C<< $node->textContent >>, but follows microformat-specific stringification
rules, including value excerption, the abbr pattern and so on.

=cut

# This function takes on too much responsibility.
# It should delegate stuff.
sub stringify
{
	my $dom        = shift;
	my $valueClass = shift || undef;
	my $doABBR     = shift || (length $valueClass);
	my $str;
	
	my %opts;
	
	if (ref($valueClass) eq 'HASH')
	{
		%opts = %$valueClass;
		
		$valueClass = $opts{'excerpt-class'};
		$doABBR     = $opts{'abbr-pattern'};
	}
	
	return unless $dom;

	# value-title
	if ($opts{'value-title'} =~ /(allow|require)/i or
	($opts{'datetime'} && $opts{'value-title'} !~ /(forbid)/i))
	{
		KIDDY: foreach my $kid ($dom->childNodes)
		{
			next if $kid->nodeName eq '#text' && $kid->textContent !~ /\S/; # skip whitespace
			
			last # anything without class='value-title' and a title attribute causes us to bail out.
				unless
				$opts{'value-title'} =~ /(lax)/i
				|| ($kid->can('hasAttribute')
				&& $kid->hasAttribute('class')
				&& $kid->hasAttribute('title')
				&& $kid->getAttribute('class') =~ /\b(value\-title)\b/);
			
			my $str = $kid->getAttribute('title');
			utf8::encode($str);
			return HTML::Microformats::Datatype::String::ms($str, $kid);
		}
	}
	return if $opts{'value-title'} =~ /(require)/i;

	# ABBR pattern
	if ($doABBR)
	{
		if ($dom->nodeType==XML_ELEMENT_NODE
			&& length $dom->getAttribute('data-cpan-html-microformats-content'))
		{
			my $title = $dom->getAttribute('data-cpan-html-microformats-content');
			return HTML::Microformats::Datatype::String::ms($title, $dom);
		}
		elsif ( ($dom->nodeType==XML_ELEMENT_NODE 
			&& $dom->tagName eq 'abbr' 
			&& $dom->hasAttribute('title'))
		||   ($dom->nodeType==XML_ELEMENT_NODE 
			&& $dom->tagName eq 'acronym' 
			&& $dom->hasAttribute('title'))
		||   ($dom->nodeType==XML_ELEMENT_NODE
			&& $dom->getAttribute('title') =~ /data\:/)
		)
		{
			my $title = $dom->getAttribute('title');
			utf8::encode($title);
	
			if ($title =~ / [\(\[\{] data\: (.*) [\)\]\}] /x
			||  $title =~ / data\: (.*) $ /x )
				{ $title = $1; }
	
			if (defined $title)
				{ return (ms $title, $dom); }
		}
		elsif ($dom->nodeType==XML_ELEMENT_NODE 
			&& $opts{'datetime'} 
			&& $dom->hasAttribute('datetime'))
		{
			my $str = $dom->getAttribute('datetime');
			utf8::encode($str);
			return HTML::Microformats::Datatype::String::ms($str, $dom);
		}
	}
	
	# Value excerpting.
	if (length $valueClass)
	{
		my @nodes = searchClass($valueClass, $dom);
		my @strs;
		if (@nodes)
		{
			foreach my $valueNode (@nodes)
			{
				push @strs, stringify($valueNode, {
					'excerpt-class'   => undef,
					'abbr-pattern'    => $doABBR,
					'datetime'        => $opts{'datetime'},
					'keep-whitespace' => 1
				});
			}
			
			# In datetime mode, be smart enough to detect when date, time and
			# timezone have been given in wrong order.
			if ($opts{'datetime'})
			{
				my $dt_things = {};
				foreach my $x (@strs)
				{
					if ($x =~ /^\s*(Z|[+-]\d{1,2}(\:?\d\d)?)\s*$/i)
						{ push @{$dt_things->{'z'}}, $1; }
					elsif ($x =~ /^\s*T?([\d\.\:]+)\s*$/i)
						{ push @{$dt_things->{'t'}}, $1; }
					elsif ($x =~ /^\s*([\d-]+)\s*$/i)
						{ push @{$dt_things->{'d'}}, $1; }
					elsif ($x =~ /^\s*T?([\d\.\:]+)\s*(Z|[+-]\d{1,2}(\:?\d\d)?)\s*$/i)
					{
						push @{$dt_things->{'t'}}, $1;
						push @{$dt_things->{'z'}}, $2;
					}
					elsif ($x =~ /^\s*(\d+)(?:[:\.](\d+))?(?:[:\.](\d+))?\s*([ap])\.?\s*[m]\.?\s*$/i)
					{
						my $h = $1;
						if (uc $4 eq 'P' && $h<12)
						{
							$h += 12;
						}
						elsif (uc $4 eq 'A' && $h==12)
						{
							$h = 0;
						}
						my $t = (defined $3) ? sprintf("%02d:%02d:%02d", $h, $2, $3) : sprintf("%02d:%02d", $h, $2);
						push @{$dt_things->{'t'}}, $t;
					}
				}
				
				if (defined $opts{'datetime-feedthrough'} && !defined $dt_things->{'d'}->[0])
				{
					push @{ $dt_things->{'d'} }, $opts{'datetime-feedthrough'}->ymd('-');
				}
				if (defined $opts{'datetime-feedthrough'} && !defined $dt_things->{'z'}->[0])
				{
					push @{ $dt_things->{'z'} }, $opts{'datetime-feedthrough'}->strftime('%z');
				}
				
				$str = sprintf("%s %s %s",
					$dt_things->{'d'}->[0],
					$dt_things->{'t'}->[0],
					$dt_things->{'z'}->[0]);
			}
			
			unless (length $str)
			{
				$str = HTML::Microformats::Datatype::String::ms((join $opts{'joiner'}, @strs), $dom);
			}
		}
	}

	my $inpre = searchAncestorTag('pre', $dom) ? 1 : 0;
	eval {
		$str = _stringify_helper($dom, $inpre, 0)
			unless defined $str;
	};
	#$str = '***UTF-8 ERROR (WTF Happened?)***' if $@;
	#$str = '***UTF-8 ERROR (Not UTF-8)***' unless utf8::is_utf8("$str");
	#$str = '***UTF-8 ERROR (Bad UTF-8)***' unless utf8::valid("$str");
	
	if ($opts{'datetime'} && defined $opts{'datetime-feedthrough'})
	{
		if ($str =~ /^\s*T?([\d\.\:]+)\s*$/i)
		{
			$str = sprintf('%s %s %s',
				$opts{'datetime-feedthrough'}->ymd('-'),
				$1,
				$opts{'datetime-feedthrough'}->strftime('%z'),
				);
		}
		elsif ($str =~ /^\s*T?([\d\.\:]+)\s*(Z|[+-]\d{1,2}(\:?\d\d)?)\s*$/i)
		{
			$str = sprintf('%s %s %s',
				$opts{'datetime-feedthrough'}->ymd('-'),
				$1,
				$2,
				);
		}
		elsif ($str =~ /^\s*([\d]+)(?:[:\.](\d+))(?:[:\.](\d+))?\s*([ap])\.?\s*[m]\.?\s*$/i)
		{
			my $h = $1;
			if (uc $4 eq 'P' && $h<12)
			{
				$h += 12;
			}
			elsif (uc $4 eq 'A' && $h==12)
			{
				$h = 0;
			}
			my $t = (defined $3) ? sprintf("%02d:%02d:%02d", $h, $2, $3) : sprintf("%02d:%02d", $h, $2);
			$str = sprintf('%s %s %s',
				$opts{'datetime-feedthrough'}->ymd('-'),
				$t,
				$opts{'datetime-feedthrough'}->strftime('%z'),
				);
		}
	}

	unless ($opts{'keep-whitespace'})
	{
		# \x1D is used as a "soft" line break. It can be "absorbed" into an adjacent
		# "hard" line break.
		$str =~ s/\x1D+/\x1D/g;
		$str =~ s/\x1D\n/\n/gs;
		$str =~ s/\n\x1D/\n/gs;
		$str =~ s/\x1D/\n/gs;
		$str =~ s/(^\s+|\s+$)//gs;
	}
	
	return HTML::Microformats::Datatype::String::ms($str, $dom);
}

sub _stringify_helper
{
	my $domNode   = shift || return;
	my $inPRE     = shift || 0;
	my $indent    = shift || 0;
	my $rv = '';

	my $tag;
	if ($domNode->nodeType == XML_ELEMENT_NODE)
	{
		$tag = lc($domNode->tagName);
	}
	elsif ($domNode->nodeType == XML_COMMENT_NODE)
	{
		return HTML::Microformats::Datatype::String::ms('');
	}
	
	# Change behaviour within <pre>.
	$inPRE++ if $tag eq 'pre';
	
	# Text node, or equivalent.
	if (!$tag || $tag eq 'img' || $tag eq 'input' || $tag eq 'param')
	{
		$rv = $domNode->getData
			unless $tag;
		$rv = $domNode->getAttribute('alt')
			if $tag && $domNode->hasAttribute('alt');
		$rv = $domNode->getAttribute('value')
			if $tag && $domNode->hasAttribute('value');

		utf8::encode($rv);

		unless ($inPRE)
		{
			$rv =~ s/[\s\r\n]+/ /gs;
		}
		
		return $rv;
	}
	
	# Breaks.
	return "\n" if ($tag eq 'br');
	return "\x1D\n====\n\n"
		if ($tag eq 'hr');
	
	# Deleted text.
	return '' if ($tag eq 'del');

	# Get stringified children.
	my (@parts, @ctags, @cdoms);
	my $extra = 0;
	if ($tag =~ /^([oud]l|blockquote)$/)
	{
		$extra += 6; # Advisory for word wrapping.
	}
	foreach my $child ($domNode->getChildNodes)
	{
		my $ctag = $child->nodeType==XML_ELEMENT_NODE ? lc($child->tagName) : undef;
		my $str  = _stringify_helper($child, $inPRE, $indent + $extra);
		push @ctags, $ctag;
		push @parts, $str;
		push @cdoms, $child;
	}
	
	if ($tag eq 'ul' || $tag eq 'dir' || $tag eq 'menu')
	{
		$rv .= "\x1D";
		my $type = lc($domNode->getAttribute('type')) || 'disc';

		for (my $i=0; defined $parts[$i]; $i++)
		{
			next unless ($ctags[$i] eq 'li');
			
			$_ = $parts[$i];
			s/(^\x1D|\x1D$)//g;
			s/\x1D+/\x1D/g;
			s/\x1D\n/\n/gs;
			s/\n\x1D/\n/gs;
			s/\x1D/\n/gs;
			s/\n/\n    /gs;

			my $marker_type = $type;
			$marker_type = lc($cdoms[$i]->getAttribute('type'))
				if (length $cdoms[$i]->getAttribute('type'));

			my $marker = '*';
			if ($marker_type eq 'circle')    { $marker = '-'; }
			elsif ($marker_type eq 'square') { $marker = '+'; }
			
			$rv .= "  $marker $_\n";
		}
		$rv .= "\n";
	}
	
	elsif ($tag eq 'ol')
	{
		$rv .= "\x1D";
		
		my $count = 1;
		$count = $domNode->getAttribute('start')
			if (length $domNode->getAttribute('start'));
		my $type = $domNode->getAttribute('type') || '1';
		
		for (my $i=0; defined $parts[$i]; $i++)
		{
			next unless ($ctags[$i] eq 'li');
			
			$_ = $parts[$i];
			s/(^\x1D|\x1D$)//g;
			s/\x1D+/\x1D/g;
			s/\x1D\n/\n/gs;
			s/\n\x1D/\n/gs;
			s/\x1D/\n/gs;
			s/\n/\n    /gs;
			
			my $marker_value = $count;
			$marker_value = $cdoms[$i]->getAttribute('value')
				if (length $cdoms[$i]->getAttribute('value'));
			
			my $marker_type = $type;
			$marker_type = $cdoms[$i]->getAttribute('type')
				if (length $cdoms[$i]->getAttribute('type'));
				
			my $marker = sprintf('% 2d', $marker_value);
			if (uc($marker_type) eq 'A' && $marker_value > 0 && $marker_value <= 26)
				{ $marker = ' ' . chr( ord($marker_type) + $marker_value - 1 ); }
			elsif ($marker_type eq 'i' && $marker_value > 0 && $marker_value <= 3999)
				{ $marker = sprintf('% 2s', roman($marker_value)); }
			elsif ($marker_type eq 'I' && $marker_value > 0 && $marker_value <= 3999)
				{ $marker = sprintf('% 2s', Roman($marker_value)); }
				
			$rv .= sprintf("\%s. \%s\n", $marker, $_);

			$count++;
		}
		$rv .= "\n";
	}

	elsif ($tag eq 'dl')
	{
		$rv .= "\x1D";
		for (my $i=0; defined $parts[$i]; $i++)
		{
			next unless ($ctags[$i] eq 'dt' || $ctags[$i] eq 'dd');
			
			if ($ctags[$i] eq 'dt')
			{
				$rv .= $parts[$i] . ':';
				$rv =~ s/\:\s*\:$/\:/;
				$rv .= "\n";
			}
			elsif ($ctags[$i] eq 'dd')
			{
				$_ = $parts[$i];
				s/(^\x1D|\x1D$)//g;
				s/\x1D+/\x1D/g;
				s/\x1D\n/\n/gs;
				s/\n\x1D/\n/gs;
				s/\x1D/\n/gs;
				s/\n/\n    /gs;
				$rv .= sprintf("    \%s\n\n", $_);
			}
		}
	}

	elsif ($tag eq 'blockquote')
	{
		$rv .= "\x1D";
		for (my $i=0; defined $parts[$i]; $i++)
		{
			next unless ($ctags[$i]);
			
			$_ = $parts[$i];
			s/(^\x1D|\x1D$)//g;
			s/\x1D+/\x1D/g;
			s/\x1D\n/\n/gs;
			s/\n\x1D/\n/gs;
			s/\x1D/\n/gs;
			s/\n\n/\n/;
			s/\n/\n> /gs;
			$rv .= "> $_\n";
		}
		$rv =~ s/> $/\x1D/;
	}
	
	else
	{
		$rv = '';
		for (my $i=0; defined $parts[$i]; $i++)
		{
			$rv .= $parts[$i];
			
			# Hopefully this is a sensible algorithm for inserting whitespace
			# between childnodes. Needs a bit more testing though.
			
			# Don't insert whitespace if this tag or the next one is a block-level element.
			# Probably need to expand this list of block elements.
#			next if ($ctags[$i]   =~ /^(p|h[1-9]?|div|center|address|li|dd|dt|tr|caption|table)$/);
#			next if ($ctags[$i+1] =~ /^(p|h[1-9]?|div|center|address|li|dd|dt|tr|caption|table)$/);
			
			# Insert whitespace unless the string already ends in whitespace, or next
			# one begins with whitespace.
#			$rv .= ' '
#				unless ($rv =~ /\s$/ || (defined $parts[$i+1] && $parts[$i+1] =~ /^\s/));
		}
		
		if ($tag =~ /^(p|h[1-9]?|div|center|address|li|dd|dt|tr|caption|table)$/ && !$inPRE)
		{
			$rv =~ s/^[\t ]//s;
			#local($Text::Wrap::columns);
			#$Text::Wrap::columns = 78 - $indent;
			$rv = "\x1D".$rv;#Text::Wrap::wrap('','',$rv);
			if ($tag =~ /^(p|h[1-9]?|address)$/)
			{
				$rv .= "\n\n";
			}
		}
		
		if ($tag eq 'sub')
			{ $rv = "($rv)"; }
		elsif ($tag eq 'sup')
			{ $rv = "[$rv]"; }
		elsif ($tag eq 'q')
			{ $rv = "\"$rv\""; }
		elsif ($tag eq 'th' || $tag eq 'td')
			{ $rv = "$rv\t"; }
	}

	return $rv;
}

=item C<< xml_stringify($node) >>

Returns an XML serialisation of a DOM element. This is conceptually equivalent
to C<< $node->toStringEC14N >>, but hides certain attributes which
HTML::Microformats::DocumentContext adds for internal processing.

=cut

sub xml_stringify
{
	my $node  = shift;
	my $clone = $node->cloneNode(1);
	
	foreach my $attr ($clone->attributes)
	{
		if ($attr->nodeName =~ /^data-cpan-html-microformats-/)
		{
			$clone->removeAttribute($attr->nodeName);
		}
	}
	foreach my $kid ($clone->getElementsByTagName('*'))
	{
		foreach my $attr ($kid->attributes)
		{
			if ($attr->nodeName =~ /^data-cpan-html-microformats-/)
			{
				$kid->removeAttribute($attr->nodeName);
			}
		}
	}
	
	$node->ownerDocument->documentElement->appendChild($clone);
	my $rv = $clone->toStringEC14N;
	$node->ownerDocument->documentElement->removeChild($clone);
	return $rv;
}

1;

__END__

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

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
