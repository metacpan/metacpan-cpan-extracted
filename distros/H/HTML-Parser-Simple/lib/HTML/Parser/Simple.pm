package HTML::Parser::Simple;

use strict;
use warnings;

use Moo;

use Tree::Simple;

has block =>
(
	default => sub {return {} },
	is      => 'rw',
);

has current_node =>
(
	default => sub {return ''},
	is      => 'rw',
);

has depth =>
(
	default => sub {return 0},
	is      => 'rw',
);

has empty =>
(
	default => sub {return {} },
	is      => 'rw',
);

has inline =>
(
	default => sub {return {} },
	is      => 'rw',
);

has input_file =>
(
	default => sub {return ''},
	is      => 'rw',
);

has node_type =>
(
	default => sub {return 'global'},
	is      => 'rw',
);

has output_file =>
(
	default => sub {return ''},
	is      => 'rw',
);

has result =>
(
	default => sub {return ''},
	is      => 'rw',
);

has root =>
(
	default => sub {return ''},
	is      => 'rw',
);

has self_close =>
(
	default => sub {return {} },
	is      => 'rw',
);

has tagged_attribute =>
(
	default => sub {return {} },
	is      => 'rw',
);

has verbose =>
(
	default => sub {return 0},
	is      => 'rw',
);

has xhtml =>
(
	default => sub {return 0},
	is      => 'rw',

	trigger =>
	sub
	{
		my($self, $new) = @_;

		$self -> _set_tagged_attribute($new);
	}
);

our $VERSION = '2.02';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> block
	({
	 address => 1,
	 applet => 1,
	 blockquote => 1,
	 button => 1,
	 center => 1,
	 dd => 1,
	 del => 1,
	 dir => 1,
	 div => 1,
	 dl => 1,
	 dt => 1,
	 fieldset => 1,
	 form => 1,
	 frameset => 1,
	 hr => 1,
	 iframe => 1,
	 ins => 1,
	 isindex => 1,
	 li => 1,
	 map => 1,
	 menu => 1,
	 noframes => 1,
	 noscript => 1,
	 object => 1,
	 ol => 1,
	 p => 1,
	 pre => 1,
	 script => 1,
	 table => 1,
	 tbody => 1,
	 td => 1,
	 tfoot => 1,
	 th => 1,
	 thead => 1,
	 'tr' => 1,
	 ul => 1,
	});

	$self -> empty
	({
	 area => 1,
	 base => 1,
	 basefont => 1,
	 br => 1,
	 col => 1,
	 embed => 1,
	 frame => 1,
	 hr => 1,
	 img => 1,
	 input => 1,
	 isindex => 1,
	 link => 1,
	 meta => 1,
	 param => 1,
	 wbr => 1,
	});

	$self -> inline
	({
	 a => 1,
	 abbr => 1,
	 acronym => 1,
	 applet => 1,
	 b => 1,
	 basefont => 1,
	 bdo => 1,
	 big => 1,
	 br => 1,
	 button => 1,
	 cite => 1,
	 code => 1,
	 del => 1,
	 dfn => 1,
	 em => 1,
	 font => 1,
	 i => 1,
	 iframe => 1,
	 img => 1,
	 input => 1,
	 ins => 1,
	 kbd => 1,
	 label => 1,
	 map => 1,
	 object => 1,
	 'q' => 1,
	 's' => 1,
	 samp => 1,
	 script => 1,
	 select => 1,
	 small => 1,
	 span => 1,
	 strike => 1,
	 strong => 1,
	 sub => 1,
	 sup => 1,
	 textarea => 1,
	 tt => 1,
	 u => 1,
	 var => 1,
	});

	$self -> self_close
	({
	 colgroup => 1,
	 dd => 1,
	 dt => 1,
	 li => 1,
	 options => 1,
	 p => 1,
	 td => 1,
	 tfoot => 1,
	 th => 1,
	 thead => 1,
	 'tr' => 1,
	});

	$self -> current_node($self -> create_new_node('root', '', Tree::Simple -> ROOT) );
	$self -> root($self -> current_node);

	if ($self -> xhtml)
	{
		# Compared to the non-XHTML re, this has an extra  ':' in the first [].

		$self -> tagged_attribute
		(
			q#^(<(\w+)((?:\s+[-:\w]+(?:\s*=\s*(?:(?:"[^"]*")|(?:'[^']*')|[^>\s]+))?)*)\s*(\/?)>)#
		);
	}
	else
	{
		$self -> tagged_attribute
		(
			q#^(<(\w+)((?:\s+[-\w]+(?:\s*=\s*(?:(?:"[^"]*")|(?:'[^']*')|[^>\s]+))?)*)\s*(\/?)>)#
		);
	}

}	# End of BUILD.

# -----------------------------------------------
# Create a new node to store the new tag.
# Each node has metadata:
# o attributes: The tag's attributes, as a string with N spaces as a prefix.
# o content:    The content before the tag was parsed.
# o name:       The HTML tag.
# o node_type:  This holds 'global' before '<head>' and between '</head>'
#               and '<body>', and after '</body>'. It holds 'head' from
#               '<head>' to </head>', and holds 'body' from '<body>' to
#               '</body>'. It's just there in case you need it.

sub create_new_node
{
	my($self, $name, $attributes, $parent) = @_;
	my($metadata) =
	{
		attributes => $attributes,
		content    => [],
		depth      => $self -> depth,
		name       => $name,
		node_type  => $self -> node_type,
	};

	return Tree::Simple -> new($metadata, $parent);

} # End of create_new_node.

# -----------------------------------------------

sub handle_comment
{
	my($self, $s) = @_;

	$self -> handle_content($s);

} # End of handle_comment.

# -----------------------------------------------

sub handle_content
{
	my($self, $s)                 = @_;
	my($count)                    = $self -> current_node -> getChildCount;
	my($metadata)                 = $self -> current_node -> getNodeValue;
	$$metadata{'content'}[$count] .= $s;

	$self -> current_node -> setNodeValue($metadata);

} # End of handle_content.

# -----------------------------------------------

sub handle_doctype
{
	my($self, $s) = @_;

	$self -> handle_content($s);

} # End of handle_doctype.

# -----------------------------------------------

sub handle_end_tag
{
	my($self, $tag_name) = @_;

	$self -> node_type('global') if ( ($tag_name eq 'head') || ($tag_name eq 'body') );

	if (! ${$self -> empty}{$tag_name})
	{
		$self -> current_node($self -> current_node -> getParent);
		$self -> depth($self -> depth - 1);
	}

} # End of handle_end_tag.

# -----------------------------------------------

sub handle_start_tag
{
	my($self, $tag_name, $attributes, $unary) = @_;

	$self -> depth($self -> depth + 1);

	if ($tag_name eq 'head')
	{
		$self -> node_type('head');
	}
	elsif ($tag_name eq 'body')
	{
		$self -> node_type('body');
	}

	my($node) = $self -> create_new_node($tag_name, $attributes, $self -> current_node);

	$self -> current_node($node) if (! ${$self -> empty}{$tag_name});

} # End of handle_start_tag.

# -----------------------------------------------

sub handle_xml_declaration
{
	my($self, $s) = @_;

	$self -> handle_content($s);

} # End of handle_xml_declaration.

# -----------------------------------------------

sub log
{
	my($self, $msg) = @_;

	print STDERR "$msg\n" if ($self -> verbose);

} # End of log.

# -----------------------------------------------

sub parse
{
	my($self, $html) = @_;
	my($original)    = $html;
	my(%special)     =
	(
	 script => 1,
	 style  => 1,
	);
	my($tagged_attribute) = $self -> tagged_attribute;

	my($in_content);
	my($offset);
	my(@stack, $s);

	for (; $html;)
	{
		$in_content = 1;

		# Make sure we're not in a script or style element.

		if (! $stack[$#stack] || ! $special{$stack[$#stack]})
		{
			# Rearrange order of testing so rarer possiblilites are further down.
			# Is it an end tag?

			$s = substr($html, 0, 2);

			if ($s eq '</')
			{
				if ($html =~ /^(<\/(\w+)[^>]*>)/)
				{
					substr($html, 0, length $1) = '';
					$in_content                 = 0;

					$self -> parse_end_tag($2, \@stack);
				}
			}

			# Is it a start tag?

			if ($in_content)
			{
				if (substr($html, 0, 1) eq '<')
				{
					# Use lc() since tags are stored in this module in lower-case.

					if (lc($html) =~ /$tagged_attribute/)
					{
						# Since the regexp matched, save matches in lower-case.
						# Then, re-match to get attributes in original case.
						# In each case:
						# o $1 => The whole string which matched.
						# o $2 => The tag name.
						# o $3 => The attributes.
						# o $4 => The trailing / if any (aka $unity).
						# But we have to lower-case the prefix '<$tag' of the string
						# to ensure the 2nd regexp actually matches.

						my(@match)                       = ($2, $3, $4);
						substr($html, 0, length($2) + 1) = lc substr($html, 0, length($2) + 1);

						if ($html =~ /$tagged_attribute/)
						{
							substr($html, 0, length $1) = '';
							$in_content                 = 0;

							# Here we use $3 from the 2nd match to get the attributes in the original case.
							$self -> parse_start_tag($match[0], $3, $match[2], \@stack);
						}
					}
				}
			}

			# Is it a comment?

			if ($in_content)
			{
				$s = substr($html, 0, 4);

				if ($s eq '<!--')
				{
					$offset = index($html, '-->');

					if ($offset >= 0)
					{
						$self -> handle_comment(substr($html, 0, ($offset + 3) ) );

						substr($html, 0, $offset + 3) = '';
						$in_content                   = 0;
					}
				}
			}

			# Is it a doctype?

			if ($in_content)
			{
				$s = substr($html, 0, 9);

				if ($s eq '<!DOCTYPE')
				{
					$offset = index($html, '>');

					if ($offset >= 0)
					{
						$self -> handle_doctype(substr($html, 0, ($offset + 1) ) );

						substr($html, 0, $offset + 1) = '';
						$in_content                   = 0;
					}
				}
			}

			# Is is an XML declaration?

			if ($self -> xhtml && $in_content)
			{
				$s = substr($html, 0, 5);

				if ($s eq '<?xml')
				{
					$offset = index($html, '?>');

					if ($offset >= 0)
					{
						$self -> handle_xml_declaration(substr($html, 0, ($offset + 2) ) );

						substr($html, 0, $offset + 2) = '';
						$in_content                   = 0;
					}
				}
			}

			if ($in_content)
			{
				$offset = index($html, '<');

				if ($offset < 0)
				{
					$self -> handle_content($html);

					$html = '';
				}
				else
				{
					$self -> handle_content(substr($html, 0, $offset) );

					substr($html, 0, $offset) = '';
				}
			}
		}
		else
		{
			my($re) = "(.*)<\/$stack[$#stack]\[^>]*>";

			# lc() is needed because only lc tag names are pushed onto the stack.

			if (lc($html) =~ /$re/s)
			{
				my($text) = $1;
				$text     =~ s/<!--(.*?)-->/$1/g;
				$text     =~ s/<!\[CDATA]\[(.*?)]]>/$1/g;

				$self -> handle_content($text);
			}

			$self -> parse_end_tag($stack[$#stack], \@stack);
		}

		if ($html eq $original)
		{
			my($msg)    = 'Parse error. ';
			my($parent) = $self -> current_node -> getParent;

			my($metadata);

			if ($parent && $parent -> can('getNodeValue') )
			{
				$metadata = $parent -> getNodeValue;
				$msg      .= "Parent tag: <$$metadata{'name'}>. ";
			}

			$metadata = $self -> current_node -> getNodeValue;
			$msg      .= "Current tag: <$$metadata{'name'}>. Next 100 chars: " . substr($html, 0, 100);

			die "$msg\n";
		}

		$original = $html;
	}

	# Clean up any remaining tags.

	$self -> parse_end_tag('', \@stack);

	# Return the invocant to allow method chaining.

	return $self;

} # End of parse.

# -----------------------------------------------

sub parse_end_tag
{
	my($self, $tag_name, $stack) = @_;
	$tag_name = lc $tag_name;

	# Find the closest opened tag of the same name.

	my($pos);

	if ($tag_name)
	{
		for ($pos = $#$stack; $pos >= 0; $pos--)
		{
			last if ($$stack[$pos] eq $tag_name);
		}
	}
	else
	{
		$pos = 0;
	}

	if ($pos >= 0)
	{
		# Close all the open tags, up the stack.

		my($count) = 0;

		for (my($i) = $#$stack; $i >= $pos; $i--)
		{
			$count++;

			$self -> handle_end_tag($$stack[$i]);
		}

		# Remove the open elements from the stack.
		# Does not work: $#$stack = $pos. Could use splice().

		pop @$stack for ($count);
	}

} # End of parse_end_tag.

# -----------------------------------------------

sub parse_file
{
	my($self, $input_file_name, $output_file_name) = @_;
	$input_file_name  ||= $self -> input_file;
	$output_file_name ||= $self -> output_file;

	$self -> input_file($input_file_name);
	$self -> output_file($output_file_name);
	$self -> log("Reading $input_file_name");

	open(my $fh, $input_file_name) || die "Can't open($input_file_name): $!\n";
	my($html);
	read($fh, $html, -s $fh);
	close $fh;

	die "Can't read($input_file_name): $!\n" if (! defined $html);

	$self -> log('Parsing');

	$self -> parse($html);

	$self -> log('Traversing');

	$self -> traverse($self -> root);

	$self -> log("Writing $output_file_name");

	open($fh, "> $output_file_name") || die "Can't open(> $output_file_name): $!\n";
	print $fh $self -> result;
	close $fh;

	# Return the invocant to allow method chaining.

	return $self;

} # End of parse_file.

# -----------------------------------------------

sub parse_start_tag
{
	my($self, $tag_name, $attributes, $unary, $stack) = @_;
	$tag_name = lc $tag_name;

	if (${$self -> block}{$tag_name})
	{
		for (; $#$stack >= 0 && ${$self -> inline}{$$stack[$#$stack]};)
		{
			$self -> parse_end_tag($$stack[$#$stack], $stack);
		}
	}

	if (${$self -> self_close}{$tag_name} && ($$stack[$#$stack] eq $tag_name) )
	{
		$self -> parse_end_tag($tag_name, $stack);
	}

	$unary = ${$self -> empty}{$tag_name} || $unary;

	push @$stack, $tag_name if (! $unary);

	$self -> handle_start_tag($tag_name, $attributes, $unary);

} # End of parse_start_tag.

# -----------------------------------------------

sub _set_tagged_attribute
{
	my($self, $new, $old) = @_;

	if ($new)
	{
		$self -> tagged_attribute
		(
			# Compared to the non-XHTML re, this has an extra  ':' in the first [].

			q#^(<(\w+)((?:\s+[-:\w]+(?:\s*=\s*(?:(?:"[^"]*")|(?:'[^']*')|[^>\s]+))?)*)\s*(\/?)>)#
		);
	}
	else
	{
		$self -> tagged_attribute
		(
			q#^(<(\w+)((?:\s+[-\w]+(?:\s*=\s*(?:(?:"[^"]*")|(?:'[^']*')|[^>\s]+))?)*)\s*(\/?)>)#
		);
	}

} # End of _set_tagged_attribute.

# -----------------------------------------------

sub traverse
{
	my($self, $node) = @_;
	my(@child)       = $node -> getAllChildren;
	my($metadata)    = $node -> getNodeValue;
	my($content)     = $$metadata{'content'};
	my($name)        = $$metadata{'name'};

	# Special check to avoid printing '<root>' when we still need to output
	# the content of the root, e.g. the DOCTYPE.

	$self -> result($self -> result . "<$name$$metadata{'attributes'}>") if ($name ne 'root');

	my($index);
	my($s);

	for $index (0 .. $#child)
	{
		$self -> result($self -> result . ($index <= $#$content && defined($$content[$index]) ? $$content[$index] : '') );
		$self -> traverse($child[$index]);
	}

	# Output the content after the last child node has been closed,
	# but before the current node is closed.

	$index = $#child + 1;

	$self -> result($self -> result . ($index <= $#$content && defined($$content[$index]) ? $$content[$index] : '') );
	$self -> result($self -> result . "</$name>") if (! ${$self -> empty}{$name} && ($name ne 'root') );

	# Return the invocant to allow method chaining.

	return $self;

} # End of traverse.

# -----------------------------------------------

1;

=head1 NAME

HTML::Parser::Simple - Parse nice HTML files without needing a compiler

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use HTML::Parser::Simple;

	# -------------------------

	# Method 1:

	my($p) = HTML::Parser::Simple -> new
	(
		input_file  => 'data/s.1.html',
		output_file => 'data/s.2.html',
	);

	$p -> parse_file;

	# Method 2:

	my($p) = HTML::Parser::Simple -> new;

	$p -> parse_file('data/s.1.html', 'data/s.2.html');

	# Method 3:

	my($p) = HTML::Parser::Simple -> new;

	print $p -> parse('<html>...</html>') -> traverse($p -> root) -> result;

Of course, these can be abbreviated by using method chaining. E.g. Method 2 could be:

	HTML::Parser::Simple -> new -> parse_file('data/s.1.html', 'data/s.2.html');

See scripts/parse.html.pl and scripts/parse.xhtml.pl.

=head1 Description

C<HTML::Parser::Simple> is a pure Perl module.

It parses HTML V 4 files, and generates a tree of nodes, with 1 node per HTML tag.

The data associated with each node is documented in the L</FAQ>.

See also L<HTML::Parser::Simple::Attributes> and L<HTML::Parser::Simple::Reporter>.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules.html> for details.

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html> for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<HTML::Parser::Simple>.

This is the class contructor.

Usage: C<< HTML::Parser::Simple -> new >>.

This method takes a hash of options.

Call C<< new() >> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options (each one of which is also a method):

=over 4

=item o input_file => $a_file_name

This takes the file name, including the path, of the input file.

Default: '' (the empty string).

=item o output_file => $a_file_name

This takes the file name, including the path, of the output file.

Default: '' (the empty string).

=item o verbose => $Boolean

This takes either a 0 or a 1.

Write more or less progress messages.

Default: 0.

=item o xhtml => $Boolean

This takes either a 0 or a 1.

0 means do not accept an XML declaration, such as <?xml version="1.0" encoding="UTF-8"?>
at the start of the input file, and some other XHTML features, explained next.

1 means accept XHTML input.

Default: 0.

The only XHTML changes to this code, so far, are:

=over 4

=item o Accept the XML declaration

E.g.: <?xml version="1.0" standalone='yes'?>.

=item o Accept attribute names containing the ':' char

E.g.: <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">.

=back

=back

=head1 Methods

=head2 block()

Returns a hashref where the keys are the names of block-level HTML tags.

The corresponding values in the hashref are just 1.

Typical keys: address, form, p, table, tr.

Note: Some keys, e.g. tr, are also returned by L</self_close()>.

=head2 current_node()

Returns the L<Tree::Simple> object which the parser calls the current node.

=head2 depth()

Returns the nesting depth of the current tag.

The method is just here in case you need it.

=head2 empty()

Returns a hashref where the keys are the names of HTML tags of type empty.

The corresponding values in the hashref are just 1.

Typical keys: area, base, input, wbr.

=head2 inline()

Returns a hashref where the keys are the names of HTML tags of type inline.

The corresponding values in the hashref are just 1.

Typical keys: a, em, img, textarea.

=head2 input_file($in_file_name)

Gets or sets the input file name used by L</parse($input_file_name, $output_file_name)>.

Note: The parameters passed in to L</parse_file($input_file_name, $output_file_name)>, take
precedence over the I<input_file> and I<output_file> parameters passed in to C<< new() >>, and over
the internal values set with C<< input_file($in_file_name) >> and
C<< output_file($out_file_name) >>.

'input_file' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 log($msg)

Print $msg to STDERR if C<< new() >> was called as C<< new(verbose => 1) >>, or if
C<< $p -> verbose(1) >> was called.

Otherwise, print nothing.

=head2 new()

This is the constructor. See L</Constructor and initialization> for details.

=head2 node_type()

Returns the type of the most recently created node, I<global>, I<head>, or I<body>.

See the first question in the L</FAQ> for details.

=head2 output_file($out_file_name)

Gets or sets the output file name used by L</parse($input_file_name, $output_file_name)>.

Note: The parameters passed in to L</parse_file($input_file_name, $output_file_name)>, take
precedence over the I<input_file> and I<output_file> parameters passed in to C<< new() >>, and over
the internal values set with C<< input_file($in_file_name) >> and
C<< output_file($out_file_name) >>.

'output_file' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 parse($html)

Returns the invocant. Thus C<< $p -> parse >> returns $p. This allows for method chaining. See the
L</Synopsis>.

Parses the string of HTML in $html, and builds a tree of nodes.

After calling C<< $p -> parse($html) >>, you must call C<< $p -> traverse($p -> root) >> before
calling C<< $p -> result >>.

Alternately, use C<< $p -> parse_file >>, which calls all these methods for you.

Note: C<< parse() >> may be called directly or via C<< parse_file() >>.

=head2 parse_file($input_file_name, $output_file_name)

Returns the invocant. Thus C<< $p -> parse_file >> returns $p. This allows for method chaining. See
the L</Synopsis>.

Parses the HTML in the input file, and writes the result to the output file.

C<< parse_file() >> calls L</parse($html)> and L</traverse($node)>, using C<< $p -> root >> for
$node.

Note: The parameters passed in to C<< parse_file($input_file_name, $output_file_name) >>, take
precedence over the I<input_file> and I<output_file> parameters passed in to C<< new() >>, and over
the internal values set with C<< input_file($in_file_name) >> and
C<< output_file($out_file_name) >>.

Lastly, the parameters passed in to C<< parse_file($input_file_name, $output_file_name) >> are used
to update the internal values set with the I<input_file> and I<output_file> parameters passed in to
C<< new() >>, or set with calls to C<< input_file($in_file_name) >> and
C<< output_file($out_file_name) >>.

=head2 result()

Returns the string which is the result of the parse.

See scripts/parse.html.pl.

=head2 root()

Returns the L<Tree::Simple> object which the parser calls the root of the tree of nodes.

=head2 self_close()

Returns a hashref where the keys are the names of HTML tags of type self close.

The corresponding values in the hashref are just 1.

Typical keys: dd, dt, p, tr.

Note: Some keys, e.g. tr, are also returned by L</block()>.

=head2 tagged_attribute()

Returns a string to be used as a regexp, to capture tags and their optional attributes.

It does not return qr/$s/; it just returns $s.

This regexp takes one of two forms, depending on the state of the I<xhtml> option. See
L</xhtml($Boolean)>.

The regexp has four (4) sets of capturing parentheses:

=over 4

=item o 1 for the whole tag and attribute and trailing / combination

E.g.: <(....)>

=item o 1 for the tag itself

E.g.: <(img)...>

=item o 1 for the optional attributes of the tag

E.g.: <img (src="/graph.svg" alt="A graph")>

=item o 1 for the optional trailing / of the tag

E.g.: <img ... (/)>

=back

=head2 traverse($node)

Returns the invocant. Thus C<< $p -> traverse >> returns $p. This allows for method chaining.
See the L</Synopsis>.

Traverses the tree of nodes, starting at $node.

You normally call this as C<< $p -> traverse($p -> root) >>, to ensure all nodes are visited.

See the L</Synopsis> for sample code.

Or, see scripts/traverse.file.pl, which uses L<HTML::Parser::Simple::Reporter>, and calls
C<< traverse($node) >> via L<HTML::Parser::Simple::Reporter/traverse_file($input_file_name)>.

=head2 verbose($Boolean)

Gets or sets the verbose parameter.

'verbose' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 xhtml($Boolean)

Gets or sets the xhtml parameter.

If you call this after object creation, the I<trigger> feature of L<Moos> is used to call
L</tagged_attribute()> so as to correctly set the regexp which recognises xhtml.

'xhtm'> is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head1 FAQ

=head2 What is the format of the data stored in each node of the tree?

The data of each node is a hash ref. The keys/values of this hash ref are:

=over 4

=item o attributes

This is the string of HTML attributes associated with the HTML tag.

Attributes are stored in lower-case.

So, <table align = 'center' summary = 'Body'> will have an attributes string of
" align = 'center' summary = 'body'".

Note the leading space.

=item o content

This is an arrayref of bits and pieces of content.

Consider this fragment of HTML:

<p>I did <i>not</i> say I <i>liked</i> debugging.</p>

When parsing 'I did ', the number of child nodes (of <p>) is 0, since <i> has not yet been detected.

So, 'I did ' is stored in the 0th element of the arrayref belonging to <p>.

Likewise, 'not' is stored in the 0th element of the arrayref belonging to the node <i>.

Next, ' say I ' is stored in the 1st element of the arrayref belonging to <p>,
because it follows the 1st child node (<i>).

Likewise, ' debugging' is stored in the 2nd element of the arrayref belonging to <p>.

This way, the input string can be reproduced by successively outputting the elements of the arrayref
of content interspersed with the contents of the child nodes (processed recusively).

Note: If you are processing this tree, never forget that there can be content after the last child
node has been closed, but before the current node is closed.

Note: The DOCTYPE declaration is stored as the 0th element of the content of the root node.

=item o depth

The nesting depth of the tag within the document.

The root is at depth 0, '<html>' is at depth 1, '<head>' and '<body>' are a depth 2, and so on.

It is just there in case you need it.

=item o name

So, the tag '<html>' will mean the name is 'html'.

Tag names are stored in lower-case.

The root of the tree is called 'root', and holds the DOCTYPE, if any, as content.

The root has the node 'html' as the only child, of course.

=item o node_type

This holds 'global' before '<head>' and between '</head>' and '<body>', and after '</body>'.

It holds 'head' for all nodes from '<head>' to '</head>', and holds 'body' from '<body>' to
'</body>'.

It is just there in case you need it.

=back

=head2 How are tags and attributes handled?

Tags are stored in lower-case, in a tree managed by L<Tree::Simple>.

Attributes are stored in the same case as in the original HTML.

The root of the tree is returned be L</root()>.

=head2 How are HTML comments handled?

They are treated as content. This includes the prefix '<!--' and the suffix '-->'.

=head2 How is DOCTYPE handled?

It is treated as content belonging to the root of the tree.

=head2 How is the XML declaration handled?

It is treated as content belonging to the root of the tree.

=head2 Does this module handle all HTML pages?

No, never.

=head2 Which versions of HTML does this module handle?

Up to V 4.

=head2 What do I do if this module does not handle my HTML page?

Make yourself a nice cup of tea, and then fix your page.

=head2 Does this validate the HTML input?

No.

For example, if you feed in a HTML page without the title tag, this module does not care.

=head2 How do I view the output HTML?

There are various ways.

=over 4

=item o See scripts/parse.html.pl

=item o By installing HTML::Revelation, of course!

Sample output:

L<http://savage.net.au/Perl-modules/html/CreateTable.html>.

=back

=head2 How do I test this module (or my file)?

Preferably, see the previous question, or...

Suggested steps:

Note: There are quite a few files involved. Proceed with caution.

=over 4

=item o Select a HTML file to test

Call this input.html.

=item o Run input.html thru reveal.pl

Reveal.pl ships with HTML::Revelation.

Call the output file output.1.html.

=item o Run input.html thru parse.html.pl

parse.html.pl ships with HTML::Parser::Simple.

Call the output file parsed.html.

=item o Run parsed.html thru reveal.pl

Call the output file output.2.html.

=item o Compare output.1.html and output.2.html

If they match, or even if they don't match, you're finished.

=back

=head2 Will you implement a 'quirks' mode to handle my special HTML file?

No, never.

Help with quirks: L<http://www.quirksmode.org/sitemap.html>.

=head2 Is there anything I should be aware of?

Yes. If your HTML file is not nice, the interpretation of tag nesting will not match
your preconceptions.

In such cases, do not seek to fix the code. Instead, fix your (faulty) preconceptions, and fix your
HTML file.

The 'a' tag, for example, is defined to be an inline tag, but the 'div' tag is a block-level tag.

I do not define 'a' to be inline, others do, e.g. L<http://www.w3.org/TR/html401/> and hence
L<HTML::Tagset>.

Inline means:

	<a href = "#NAME"><div class = 'global_toc_text'>NAME</div></a>

will I<not> be parsed as an 'a' containing a 'div'.

The 'a' tag will be closed before the 'div' is opened. So, the result will look like:

	<a href = "#NAME"></a><div class = 'global_toc_text'>NAME</div>

To achieve what was presumably intended, use 'span':

	<a href = "#NAME"><span class = 'global_toc_text'>NAME</span></a>

Some people (*cough* *cough*) have had to redo their entire websites due to this very problem.

Of course, this is just one of a vast set of possible problems.

You have been warned.

=head2 Why did you use Tree::Simple but not Tree or Tree::Fast or Tree::DAG_Node?

During testing, Tree::Fast crashed, so I replaced it with Tree and everything worked. Spooky.

Late news: Tree does not cope with an arrayref stored in the metadata, so I have switched to
L<Tree::DAG_Node>.

Stop press: As an experiment I switched to L<Tree::Simple>. Since it also works I will just keep
using  it.

=head2 Why is this module not called HTML::Parser::PurePerl?

=over 4

=item o The API

That name sounds like a pure Perl version of the same API as used by HTML::Parser.

But the 2 APIs are not, and are not meant to be, compatible.

=item o The tie-in

Some people might falsely assume L<HTML::Parser> can automatically fall back to
L<HTML::Parser::PurePerl> in the absence of a compiler.

=back

=head2 How do I output my own stuff while traversing the tree?

=over 4

=item o The sophisticated way

As always with OO code, sub-class! In this case, you write a new version of the traverse() method.

See L<HTML::Parser::Simple::Reporter>, for example. It overrides L</traverse($node)>.

=item o The crude way

Alternately, implement another method in your sub-class, e.g. process(), which recurses like
traverse(). Then call parse() and process().

=back

=head2 How is the source formatted?

I edit with UltraEdit. That means, in general, leading 4-space tabs.

All vertical alignment within lines is done manually with spaces.

Perl::Critic is off the agenda.

=head2 Why did you choose Moos?

For the 2012 Google Code-in, I had a quick look at 122 class-building classes, and decided
L<Moos> was suitable, given it is pure-Perl and has the trigger feature I needed.

See L<http://savage.net.au/Module-reviews/html/gci.2012.class.builder.modules.html>.

=head1 Credits

This Perl HTML parser has been converted from a JavaScript one written by John Resig.

L<http://ejohn.org/files/htmlparser.js>.

Well done John!

Note also the comments published here:

L<http://groups.google.com/group/envjs/browse_thread/thread/edd9033b9273fa58>.

=head1 Repository

L<https://github.com/ronsavage/HTML-Parser-Simple>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML::Parser::Simple>.

=head1 Author

C<HTML::Parser::Simple> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2009.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2009 Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
