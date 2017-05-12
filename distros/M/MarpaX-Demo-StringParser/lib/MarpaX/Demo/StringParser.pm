package MarpaX::Demo::StringParser;

use strict;
use utf8;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use File::Slurp; # For read_file().

use Log::Handler;

use Marpa::R2;

use Moo;

use Set::Array;

use Text::CSV;

use Tree::DAG_Node;

use Types::Standard qw/Any ArrayRef HashRef Int Str/;

use Try::Tiny;

has bnf =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has description =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has grammar =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any, # 'Marpa::R2::Scanless::G'.
	required => 0,
);

has graph_text =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has input_file =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has logger =>
(
	default  => sub{return undef},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has maxlevel =>
(
	default  => sub{return 'notice'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has minlevel =>
(
	default  => sub{return 'error'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has known_events =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has recce =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any, # 'Marpa::R2::Scanless::R'.
	required => 0,
);

has stack =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has tree =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has uid =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

our $VERSION = '2.04';

# --------------------------------------------------
# For accepted and rejected by Marpa, see
# Marpa-R2-2.094000/lib/Marpa/R2/meta/metag.bnf.

sub BUILD
{
	my($self) = @_;

	if (! defined $self -> logger)
	{
		$self -> logger(Log::Handler -> new);
		$self -> logger -> add
		(
			screen =>
			{
				alias          => 'logger',
				maxlevel       => $self -> maxlevel,
				message_layout => '%m',
				minlevel       => $self -> minlevel,
			}
		);
	}

	# Policy: Event names are always the same as the name of the corresponding lexeme.

	$self -> bnf
	(
<<'END_OF_GRAMMAR'

:default				::= action => [values]

lexeme default			=  latm => 1		# Longest Acceptable Token Match.

:start					::= graph_grammar

graph_grammar			::= graph_definition

# Graph stuff.

graph_definition		::= node_definition
							| edge_definition
# Node stuff

node_definition			::= node_statement
							| node_statement graph_definition

node_statement			::= node_name_token
							| node_name_token attribute_definition
							| node_statement (',') node_statement

node_name_token			::= start_node end_node		# Allow for the anonymous node.
							| start_node node_name end_node

# Edge stuff

edge_definition			::= edge_statement
							| edge_statement graph_definition

edge_statement			::= edge_name
							| edge_name attribute_definition
							| edge_statement (',') edge_statement

edge_name				::= directed_edge
							| undirected_edge

# Attribute stuff.

attribute_definition	::= attribute_statement+

attribute_statement		::= start_attributes string_token_set end_attributes

string_token_set		::= string_token_pair+

string_token_pair		::= literal_label
							| attribute_name (':') attribute_value

# Lexemes in alphabetical order.

:lexeme					~ attribute_name			pause => before		event => attribute_name

attribute_name			~ string_char_set+

:lexeme					~ attribute_value			pause => before		event => attribute_value

attribute_value			~ string_char_set+

:lexeme					~ directed_edge				pause => before		event => directed_edge		priority => 2
directed_edge			~ '->'

:lexeme					~ end_attributes			pause => before		event => end_attributes		priority => 1
end_attributes			~ '}'

:lexeme					~ end_node					pause => before		event => end_node			priority => 1
end_node				~ ']'

escaped_char			~ '\' [[:print:]]

# Use ' here just for the UltraEdit syntax hiliter.

:lexeme					~ literal_label				pause => before		event => literal_label		priority => 1
literal_label			~ 'label'

:lexeme					~ node_name					pause => before		event => node_name

node_name				~ string_char_set+

:lexeme					~ start_attributes			pause => before		event => start_attributes
start_attributes		~ '{'

:lexeme					~ start_node				pause => before		event => start_node
start_node				~ '['

string_char_set			~ escaped_char
							| [^;:}\]] # Neither a separator [;:] nor a terminator [}\]].

:lexeme					~ undirected_edge			pause => before		event => undirected_edge	priority => 2
undirected_edge			~ '--'

# Boilerplate.

:discard				~ whitespace
whitespace				~ [\s]+

END_OF_GRAMMAR
	);

	$self -> grammar
	(
		Marpa::R2::Scanless::G -> new
		({
			source => \$self -> bnf
		})
	);

	$self -> recce
	(
		Marpa::R2::Scanless::R -> new
		({
			grammar => $self -> grammar,
		})
	);

	my(%event);

	for my $line (split(/\n/, $self -> bnf) )
	{
		$event{$1} = 1 if ($line =~ /event\s+=>\s+(\w+)/);
	}

	$self -> known_events(\%event);

	# Since $self -> tree has not been initialized yet,
	# we can't call our _add_daughter() until after this statement.

	$self -> tree(Tree::DAG_Node -> new({name => 'root', attributes => {uid => 0} }));
	$self -> stack([$self -> tree -> root]);

	# This cut-down version of Graph::Easy::Marpa has no prolog (unlike Graph::Marpa).
	# So, all tokens in the input are descended from the 'graph' node.

	for my $name (qw/prolog graph/)
	{
		$self -> _add_daughter($name, {});
	}

	# The 'prolog' daughter is the parent of all items in the prolog, but is not used here.
	# It is used in GraphViz2::Marpa;
	# The 'graph' daughter gets pushed onto the stack because in this module's grammar,
	# all items belong to the graph.

	my(@daughters) = $self -> tree -> daughters;
	my($index)     = 1; # 0 => prolog, 1 => graph.
	my($stack)     = $self -> stack;

	push @$stack, $daughters[$index];

	$self -> stack($stack);

} # End of BUILD.

# ------------------------------------------------

sub _add_daughter
{
	my($self, $name, $attributes)  = @_;
	$$attributes{uid} = $self -> uid($self -> uid + 1);
	my($node)         = Tree::DAG_Node -> new({name => $name, attributes => $attributes});
	my($stack)        = $self -> stack;

	$$stack[$#$stack] -> add_daughter($node);

} # End of _add_daughter.

# --------------------------------------------------

sub clean_after
{
	my($self, $s) = @_;

	$s =~ s/^\s+//;
	$s =~ s/\s+$//;
	$s =~ s/^([\"\'])(.*)\1$/$2/; # The backslashes are just for the UltraEdit syntax hiliter.

	return $s;

} # End of clean_after.

# --------------------------------------------------

sub clean_before
{
	my($self, $s) = @_;

	$s =~ s/\s*;\s*$//;
	$s =~ s/^\s+//;
	$s =~ s/\s+$//;
	$s =~ s/^(<)\s+/$1/;
	$s =~ s/\s+(>)$/$1/;

	return $s;

} # End of clean_before.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> log($level => $s) if ($self -> logger);

} # End of log.

# --------------------------------------------------

sub _process
{
	my($self)       = @_;
	my($string)     = $self -> clean_before($self -> graph_text);
	my($length)     = length $string;
	my($last_event) = '';
	my($format)     = '%-20s    %5s    %5s    %5s    %-s';

	$self -> log(debug => sprintf($format, 'Event', 'Start', 'Span', 'Pos', 'Lexeme') );

	# We use read()/lexeme_read()/resume() because we pause at each lexeme.

	my($event_name);
	my(@fields);
	my($lexeme, $literal);
	my($span, $start);

	for
	(
		my $pos = $self -> recce -> read(\$string);
		$pos < $length;
		$pos = $self -> recce -> resume($pos)
	)
	{
		$event_name     = $self -> _validate_event;
		($start, $span) = $self -> recce -> pause_span;
		$pos            = $self -> recce -> lexeme_read($event_name);
		$literal        = substr($string, $start, $pos - $start);
		$lexeme         = $self -> recce -> literal($start, $span);

		$self -> log(debug => sprintf($format, $event_name, $start, $span, $pos, $lexeme) );

		if ($event_name eq 'attribute_name')
		{
			$fields[0] = $self -> clean_after($literal);
		}
		elsif ($event_name eq 'attribute_value')
		{
			$literal = $self -> clean_after($literal);

			$self -> _add_daughter($fields[0], {value => $literal});

			@fields = ();

			# Skip the separator.

			while ( ($pos < (length($string) - 1) ) && (substr($string, $pos, 1) =~ /[\s;]/) ) { $pos++ };
		}
		elsif ($event_name eq 'directed_edge')
		{
			$self -> _add_daughter('edge_id', {value => $self -> clean_after($literal)});
		}
		elsif ($event_name eq 'end_attributes')
		{
			$self -> _process_brace($literal);
		}
		elsif ($event_name eq 'end_node')
		{
			# Is this the anonymous node?

			if ($last_event eq 'start_node')
			{
				$self -> _add_daughter('node_id', {value => ''});
			}
		}
		elsif ($event_name eq 'literal_label')
		{
			push @fields, $literal;

			$pos    = $self -> _process_label($self -> recce, \@fields, $string, $length, $pos);
			@fields = ();
		}
		elsif ($event_name eq 'node_name')
		{
			$literal = $self -> clean_after($literal);

			$self -> _add_daughter('node_id', {value => $literal});
		}
		elsif ($event_name eq 'start_attributes')
		{
			$self -> _process_brace($literal);
		}
		elsif ($event_name eq 'start_node')
		{
			# Do nothing.
		}
		elsif ($event_name eq 'undirected_edge')
		{
			$self -> _add_daughter('edge_id', {value => $self -> clean_after($literal)});
		}

		$last_event = $event_name;
    }

	if ($self -> recce -> ambiguity_metric > 1)
	{
		$self -> log(notice => 'Ambiguous parse');
	}

	if (my $ambiguous_status = $self -> recce -> ambiguous)
	{
		$self -> log(notice => "Parse is ambiguous: $ambiguous_status.");
	}

	# Return a defined value for success and undef for failure.

	return $self -> recce -> value;

} # End of _process.

# --------------------------------------------------

sub _process_brace
{
	my($self, $name) = @_;

	# When a '{' is encountered, the last thing pushed becomes it's parent.
	# Likewise, if '}' is encountered, we pop the stack.

	my($stack) = $self -> stack;

	if ($name eq '{')
	{
		my(@daughters) = $$stack[$#$stack] -> daughters;

		push @$stack, $daughters[$#daughters];

		$self -> _process_token('literal', $name);
	}
	else
	{
		$self -> _process_token('literal', $name);

		pop @$stack;

		$self -> stack($stack);
	}

} # End of _process_brace.

# ------------------------------------------------

sub _process_html
{
	my($self, $recce, $fields, $string, $length, $pos) = @_;

	my($bracket_count) = 0;
	my($open_bracket)  = '<';
	my($close_bracket) = '>';
	my($previous_char) = '';
	my($label)         = '';

	my($char);

	while ($pos < $length)
	{
		$char  = substr($string, $pos, 1);
		$label .= $char;

		if ($previous_char eq '\\')
		{
		}
		elsif ($char eq $open_bracket)
		{
			$bracket_count++;
		}
		elsif ($char eq $close_bracket)
		{
			$bracket_count--;

			if ($bracket_count == 0)
			{
				$pos++;

				last;
			}
		}

		$previous_char = $char;

		$pos++;
	}

	$label = $self -> clean_after($label);

	if ( ($label =~ /^</) && ($label !~ /^<.*>$/) )
	{
		my($line, $column) = $recce -> line_column;

		die "Mismatched <> in HTML !$label! at (line, column) = ($line, $column)\n";
	}

	push @$fields, $label;

	return $self -> _skip_separator($string, $length, $pos, ';');

} # End of _process_html.

# ------------------------------------------------

sub _process_label
{
	my($self, $recce, $fields, $string, $length, $pos) = @_;

	$pos = $self -> _skip_separator($string, $length, $pos, ':');

	return $pos if ($pos >= $length);

	my($char) = substr($string, $pos, 1);

	if ($char eq "'")
	{
		$pos = $self -> _process_quotes($recce, $fields, $string, $length, $pos, "'");
	}
	elsif ($char eq '"')
	{
		$pos = $self -> _process_quotes($recce, $fields, $string, $length, $pos, '"');
	}
	elsif ($char eq '<')
	{
		$pos = $self -> _process_html($recce, $fields, $string, $length, $pos);
	}
	else
	{
		$pos = $self -> _process_unquoted($recce, $fields, $string, $length, $pos);
	}

	for (my $i = 0; $i < $#$fields; $i += 2)
	{
		$self -> _add_daughter($$fields[$i], {value => $$fields[$i + 1]});
	}

	return $pos;

} # End of _process_label.

# ------------------------------------------------

sub _process_quotes
{
	my($self, $recce, $fields, $string, $length, $pos, $terminator) = @_;

	my($previous_char) = '';
	my($label)         = '';
	my($quote_count)   = 0;

	my($char);

	while ($pos < $length)
	{
		$char = substr($string, $pos, 1);

		if ( ($previous_char ne '\\') && ($char eq $terminator) )
		{
			$quote_count++;

			if ($quote_count == 2)
			{
				$label .= $char;

					$pos++;

				last;
			}
		}

		$label         .= $char;
		$previous_char = $char;

		$pos++;
	}

	# Don't call clean_after, since it removes the ' and " we are about to check.

	$label =~ s/^\s+//;
	$label =~ s/\s+$//;

	if ( ($label =~ /^['"]/) && ($label !~ /^(['"]).*\1$/) )
	{
		# Use ' and " here just for the UltraEdit syntax hiliter.

		my($line, $column) = $recce -> line_column;

		die "Mismatched quotes in label !$label! at (line, column) = ($line, $column)\n";
	}

	$label = $self -> clean_after($label);

	push @$fields, $label;

	$self -> log(debug => "_process_quotes(). Label !$label!");

	return $self -> _skip_separator($string, $length, $pos, ';');

} # End of _process_quotes.

# --------------------------------------------------

sub _process_token
{
	my($self, $name, $value) = @_;

	$self -> _add_daughter($name, {value => $value});

} # End of _process_token.

# ------------------------------------------------

sub _process_unquoted
{
	my($self, $recce, $fields, $string, $length, $pos) = @_;
	my($re) = qr/[;}]/;

	if (substr($string, $pos, 1) =~ $re)
	{
		push @$fields, '';

		return $pos;
	}

	my($previous_char) = '';
	my($label)         = '';
	my($quote_count)   = 0;

	my($char);

	while ($pos < $length)
	{
		$char = substr($string, $pos, 1);

		last if ( ($previous_char ne '\\') && ($char =~ $re) );

		$label         .= $char;
		$previous_char = $char;

		$pos++;
	}

	$label = $self -> clean_after($label);

	push @$fields, $label;

	return $self -> _skip_separator($string, $length, $pos, ';');

} # End of _process_unquoted.

# --------------------------------------------------

sub run
{
	my($self) = @_;

	if ($self -> description)
	{
		# Assume graph is a single line without comments.

		$self -> graph_text($self -> description);
	}
	elsif ($self -> input_file)
	{
		# Quick removal of whole-line C++ and hash comments.

		$self -> graph_text(join(' ', grep{! m!^(?:#|//)!} read_file($self -> input_file, binmode => ':encoding(utf-8)') ) );
	}
	else
	{
		die "Error: You must provide a graph using one of -input_file or -description\n";
	}

	# Return 0 for success and 1 for failure.

	my($result) = 0;

	try
	{
		if (defined (my $value = $self -> _process) )
		{
			$self -> log(info => join("\n", @{$self -> tree -> tree2string}) );
		}
		else
		{
			$result = 1;

			$self -> log(error => 'Parse failed');
		}
	}
	catch
	{
		$result = 1;

		$self -> log(error => "Parse failed. Error: $_");
	};

	$self -> log(info => "Parse result: $result (0 is success)");

	# Return 0 for success and 1 for failure.

	return $result;

} # End of run.

# ------------------------------------------------

sub _skip_separator
{
	my($self, $string, $length, $pos, $separator) = @_;
	my($re) = qr/[\s$separator]/;

	my($char);

	while ($pos < $length - 1)
	{
		$char = substr($string, $pos, 1);

		last if ($char !~ $re);

		$pos++;
	}

	return $pos;

} # End of _skip_separator.

# ------------------------------------------------

sub _validate_event
{
	my($self)        = @_;
	my(@event)       = @{$self -> recce -> events};
	my($event_count) = scalar @event;

	if ($event_count > 1)
	{
		$self -> log(error => "Events triggered: $event_count (should be 1). Names: " . join(', ', map{${$_}[0]} @event) . '.');

		die "The code only handles 1 event at a time\n";
	}

	my($event_name) = ${$event[0]}[0];

	if (! ${$self -> known_events}{$event_name})
	{
		my($msg) = "Unexpected event name '$event_name'";

		$self -> log(error => $msg);

		die "$msg\n";
	}

	return $event_name;

} # End of _validate_event.

# --------------------------------------------------

1;

=pod

=head1 NAME

L<MarpaX::Demo::StringParser> - Deprecated. Use under the name MarpaX::Languages::Dash

=head1 Synopsis

Typical usage:

	perl -Ilib scripts/parse.pl -de '[node]{color:blue; label: "Node name"}' -max info
	perl -Ilib scripts/parse.pl -i data/node.04.dash -max info

You can use scripts/parse.sh to simplify this process, but it assumes you're input file is in data/:

	scripts/parse.sh node.04 -max info

See L<the demo page|http://savage.net.au/Perl-modules/html/marpax.demo.stringparser/> for sample
input and output.

Also, see L<the article|http://savage.net.au/Ron/html/Conditional.preservation.of.whitespace.html>
based on this module.

=head1 Description

This module implements a parser for L</DASH> (below), a wrapper language around Graphviz's
L<DOT|http://graphviz.org/content/dot-language>. That is, the module is a pre-processor for the
DOT language.

Specifically, this module demonstrates how to use L<Marpa::R2>'s capabilities to have Marpa
repeatedly pass control back to code in your own module, during the parse, to handle those cases
where you don't want Marpa's default processing to occur.

This allows the code to deal with the classic case of where you wish to preserve whitespace in some
contexts, but also want Marpa to discard whitespace in all other contexts.

DASH is easier to use than DOT, which means the user can specify graphs very simply, without having
to learn DOT.

The DASH language is actually a cut-down version of the language used by L<Graph::Easy>. For a full
explanation of the Graph::Easy language, see L<http://bloodgate.com/perl/graph/manual/>.

The wrapper is parsed into a tree of tokens managed by L<Tree:DAG_Node>.

If requested by the user, the tree is passed to the default renderer
L<MarpaX::Demo::StringParser::Renderer>. Various options allow the user to control the output, as
an SVG (PNG, ...) image, and to save the DOT version of the graph.

In the past, the code in this module was part of Graph::Easy::Marpa, but that latter module has
been deleted from CPAN, and all it's new code and features, together with bug fixes, is in the
current module.

Note that this module's usage of Marpa's adverbs I<event> and I<pause> should be regarded as an
intermediate/advanced technique. For people just beginning to use Marpa, use of the I<action> adverb
is the recommended technique.

The article mentioned above discusses important issues regarding the timing sequence of I<pauses>
and I<actions>.

All this assumes a relatively recent version of Marpa, one in which its Scanless interface (SLIF)
is implemented. I'm currently (2014-10-10) using L<Marpa::R2> V 2.096000.

Lastly, the parser and renderer will be incorporated into the next major release (V 2.00) of
L<GraphViz2::Marpa>, which parses DOT files.

=head1 Installation

Install L<MarpaX::Demo::StringParser> as you would for any C<Perl> module:

Run:

	cpanm MarpaX::Demo::StringParser

or run:

	sudo cpan MarpaX::Demo::StringParser

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Scripts Shipped with this Module

All scripts are shipped in the scripts/ directory.

=over 4

=item o copy.config.pl

This is for use by the author. It just copies the config file out of the distro, so the script
generate.index.pl (which uses HTML template stuff) can find it.

=item o find.config.pl

This cross-checks the output of copy.config.pl.

=item o dash2svg.pl

Converts all data/*.dash files into the corresponding html/*.svg files.

Used by generate.demo.sh.

=item o generate.demo.sh

This generates all the SVG files for the data/*.dash files, and then generates html/index.html.

And then it copies the demo output to my dev web server's doc root, where I can cross-check it.

=item o generate.index.pl

This constructs a web page containing all the html/*.svg files.

=item o parse.pl

This runs a parse on a single input file. Run 'parse.pl -h' for details.

=item o parse.sh

This simplifies running parse.pl.

=item o pod2html.sh

This converts all lib/*.pm files into their corresponding *.html versions, for proof-reading and
uploading to my real web site.

=item o render.pl

This runs a parse on a single input file, and coverts the output into an SVG file. Run 'render.pl -h'
for details.

=item o render.sh

This simplifies running render.pl.

=back

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = MarpaX::Demo::StringParser -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<MarpaX::Demo::StringParser>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. description($graph)]):

=over 4

=item o description => '[node.1]->[node.2]'

Specify a string for the graph definition.

You are strongly encouraged to surround this string with '...' to protect it from your shell if using
this module directly from the command line.

See also the I<input_file> key which reads the graph from a file.

The I<description> key takes precedence over the I<input_file> key.

Default: ''.

=item o input_file => $graph_file_name

Read the graph definition from this file.

See also the I<description> key to read the graph from the command line.

The whole file is slurped in as a single graph.

The first lines of the file can start with /^\s*#/, and will be discarded as comments.

The I<description> key takes precedence over the I<input_file> key.

Default: ''.

=item o logger => $logger_object

Specify a logger object.

To disable logging, just set logger to the empty string.

Default: An object of type L<Log::Handler>.

=item o maxlevel => $level

This option is only used if this module creates an object of type L<Log::Handler>.

See L<Log::Handler::Levels>.

Default: 'notice'. A typical choice is 'info' or 'debug'.

=item o minlevel => $level

This option is only used if this module creates an object of type L<Log::Handler>.

See L<Log::Handler::Levels>.

Default:  'error'.

No lower levels are used.

=back

=head1 Methods

=head2 clean_before($s)

Cleans the input string before the next step in the parse process.

Typically only ever called once.

Returns the cleaned string.

=head2 clean_after($s)

Cleans the input string after each step in the parse process.

Typically called many times, once on each output token.

Returns the cleaned string.

=head2 description([$graph])

Here, the [] indicate an optional parameter.

Gets or sets the graph string to be parsed.

See also the L</input_file([$graph_file_name])> method.

The value supplied to the description() method takes precedence over the value read from the input file.

Also, I<description> is an option to new().

=head2 graph_text([$graph])

Here, the [] indicate an optional parameter.

Returns the value of the graph definition string, from either the command line or a file.

=head2 input_file([$graph_file_name])

Here, the [] indicate an optional parameter.

Gets or sets the name of the file to read the graph definition from.

See also the L</description([$graph])> method.

The whole file is slurped in as a single graph.

The first few lines of the file can start with /^\s*#/, and will be discarded as comments.

The value supplied to the description() method takes precedence over the value read from the input file.

Also, I<input_file> is an option to new().

=head2 log($level, $s)

Calls $self -> logger -> log($level => $s) if ($self -> logger).

=head2 run()

This is the only method the caller needs to call. All parameters are supplied to new().

Returns 0 for success and 1 for failure.

=head2 recce()

Returns an object of type L<Marpa::R2::Scanless::R>.

=head2 tree()

Returns an object of type L<Tree::DAG_Node>.

=head1 DASH Syntax

See L<the demo page|http://savage.net.au/Perl-modules/html/marpax.demo.stringparser/> for sample
input and output.

The examples in the following sections are almost all taken from data/*.dash, in the distro.

=head2 Graphs in DASH

	1: A graph definition may continue over multiple lines.
	2: Lines beginning with either '#' or '//' are discarded as comments.
	3: A node name or an edge name must never be split over multiple lines.
	4: Attributes may be split over lines, but do not split either the name or value of the
		attribute over multiple lines.
		Note: Attribute values can contain various escaped characters, e.g. \n.
	5: A graph may start or end with an edge, and even have contiguous edges.
		See data/edge.06.dash (or the demo page). Graphviz does not allow any of these
		possibilities, so the default renderer fabricates anonymous nodes and inserts them where
		they will satisfy the requirements of Graphviz.

Examples:

	1: A graph split over 10 lines:
		[node.1] {label: "n 1"}
		-> {label: 'e 1'}
		-> {label: e 2}
		[] {label: n 2}
		-> {label  :  e 3}
		[node.3] {label: "n 3"}
		-> {label: 'e 4'},
		-> {label: e 5}
		[] {label: n 2}
		-> {label  :  e 6}
	2: A graph split over 14 lines:
		->
		->

		[node]
		[node] ->
		-> {label: Start} -> {color: red} [node.1] {color: green} -> [node.2]
		[node.1] [node.2] [node.3]

		[]
		[node.1]
		[node 1]
		['node.2']
		["node.3"]
		[     From here     ] -> [     To there     ]

=head2 Nodes in DASH

Node names:

	1: Are delimited by '[' and ']'.
	2: May be quoted with " or '.
	3: Allow escaped characters, using '\'.
	4: Allow internal spaces, even if not quoted.
	5: May be separated with nothing (juxtaposed), with whitespace, or with ','.
		This is called 'Daisy-chaining'.

See L<Daisy chains|https://en.wikipedia.org/wiki/Daisy_chain> for the origin of this term.

Examples:

	1: The anonymous node: []
	2: The anonymous node, with attributes (explained below): []{color:red}
	3: A named node: [Marpa]
	4: Juxtaposed nodes: [Perl][Marpa] or [Perl]  [Marpa] or [Perl], [Marpa]
	5: A named node with an internal space: [Perl 6]
	6: A named node with attributes: [node.1]{label: A and B}
	7: A named node with spaces: [    node.1    ]
		These spaces are discarded.
	8: A named node with attributes, with spaces: [  node.1  ] { label : '  A  Z  '  }
		The spaces around 'node.1' are discarded.
		The spaces around '  A  Z  ' are discarded.
		The spaces inside '  A  Z  ' are preserved (because of the quotes).
		Double-quotes act in the same way.
	9: A named node with attributes, with spaces:
		[ node.1 ] {  label  :  Flight Path from Melbourne to London  }
		Space preservation is as above.
	10: A named node with escaped characters: [\[node\]]
		The '[' and ']' chars are preserved.
	11: A named node with [] in name: [[ \]]
		However, since '[' and ']' delimit node names, you are I<strongly> advised to escape such
		characters.
	12: A named node with quotes, spaces, and escaped chars: [" a \' b \" c"]
	13: A complete graph:
		[node.1]
		-> {arrowhead: odot; arrowtail: ediamond; color: green; dir: both; label: A 1; penwidth: 1}
		-> {color: blue; label: B 2; penwidth: 3}
		-> {arrowhead: box; arrowtail: invdot; color: maroon; dir: both; label: C 3; penwidth: 5}
		[] {label: 'Some node'}
		-> [node.2]

=head2 Edges in DASH

Edge names:

	1: Are '->'
		This is part of a directed graph.
	2: Or '--'
		This is part of an undirected graph.
	3: May be separated with nothing (juxtaposed), with whitespace, or with ','.
		This is called 'Daisy-chaining'.

See L<Daisy chains|https://en.wikipedia.org/wiki/Daisy_chain> for the origin of this term.

It makes no sense to combine '->' and '--' in a single graph, because Graphviz will automatically
reject such input. In other words, directed and undirected graphs are mutually exclusive.

So, if any edge in your graph is undirected (you use '--'), then every edge must use '--' and the
same for '->'.

Examples:

	1: An edge with attributes: -> {color:cornflowerblue; label: This edge's color is blueish ;}
	2: Juxtaposed edges without any spacing and without attributes: ------
	3: Juxtaposed edges (without comma) with attributes:
		-- {color: cornflowerblue; label: Top row\nBottom row}
		-- {color:red; label: Edges use cornflowerblue and red}
	4: An edge with attributes, with some escaped characters:
		-> {color:cornflowerblue; label: Use various escaped chars (\' \" \< \>) in label}

=head2 Attributes in DASH

Attributes:

	1: Are delimited by '{' and '}'.
	2: Consist of a C<name> and a C<value>, separated by ':'.
	3: Are separated by ';'.
	4: The DOT language defines a set of escape characters acceptable in such a C<value>.
	5: Allow quotes and whitespace as per node names.
		This must be true because the same non-Marpa parsers are used for both.
	6: Attribute values can be HTML-like. See the Graphviz docs for why we say 'HTML-like' and
		not HTML. See data/table.*.ge for examples.

See L<HTML-like labels|http://www.graphviz.org/content/node-shapes#html> for details.

Examples:

	1: -- {color: cornflowerblue; label: Top row\nBottom row}
		Note the use of '\n' in the value of the label.

=head1 FAQ

=head2 What is the grammar parsed by this module?

See L</DASH> just above.

=head2 How is the parsed graph stored in RAM?

Items are stored in a tree managed by L<Tree::DAG_Node>.

The sample code in the L</Synopsis> will display a tree:

	perl -Ilib scripts/parse.pl -i data/node.04.dash -max info

Output:

	root. Attributes: {uid => "0"}
	   |---prolog. Attributes: {uid => "1"}
	   |---graph. Attributes: {uid => "2"}
	       |---node_id. Attributes: {uid => "3", value => "node.1"}
	       |   |---literal. Attributes: {uid => "4", value => "{"}
	       |   |---label. Attributes: {uid => "5", value => "A and B"}
	       |   |---literal. Attributes: {uid => "6", value => "}"}
	       |---node_id. Attributes: {uid => "7", value => "node.2"}
	           |---literal. Attributes: {uid => "8", value => "{"}
	           |---label. Attributes: {uid => "9", value => "A or B"}
	           |---literal. Attributes: {uid => "10", value => "}"}
	Parse result: 0 (0 is success)

See also the next question.

=head2 What is the structure of the tree of parsed tokens?

From the previous answer, you can see the root has 2 daughters, with the 'prolog' daughter not
currently used. It is used by L<GraphViz2::Marpa>.

The 'graph' daughter (sub-tree) is what's processed by the default rendering engine
L<MarpaX::Demo::StringParser::Renderer> to convert the tree (i.e. the input file) into a DOT file
and into an image.

=head2 Does this module handle utf8?

Yes. See the last sample on L<the demo page|http://savage.net.au/Perl-modules/html/marpax.demo.stringparser/>.

=head2 Why doesn't the parser handle my HTML-style labels?

Traps for young players:

=over 4

=item o The <br /> component must include the '/'

=back

=head2 Why do I get error messages like the following?

	Error: <stdin>:1: syntax error near line 1
	context: digraph >>>  Graph <<<  {

Graphviz reserves some words as keywords, meaning they can't be used as an ID, e.g. for the name of the graph.
So, don't do this:

	strict graph graph{...}
	strict graph Graph{...}
	strict graph strict{...}
	etc...

Likewise for non-strict graphs, and digraphs. You can however add double-quotes around such reserved words:

	strict graph "graph"{...}

Even better, use a more meaningful name for your graph...

The keywords are: node, edge, graph, digraph, subgraph and strict. Compass points are not keywords.

See L<keywords|http://www.graphviz.org/content/dot-language> in the discussion of the syntax of DOT
for details.

=head2 What is the homepage of Marpa?

L<http://savage.net.au/Marpa.html>.

=head2 How do I reconcile Marpa's approach with classic lexing and parsing?

I've included in a recent article a section called
L<Constructing a Mental Picture of Lexing and Parsing|http://savage.net.au/Ron/html/Conditional.preservation.of.whitespace.html#Constructing_a_Mental_Picture_of_Lexing_and_Parsing>
which is aimed at helping us think about this issue.

=head2 How did you generate the html/*.svg files?

With a private script which uses L<Graph::Easy::Marpa::Renderer::GraphViz2> V 2.00. This script is not shipped
in order to avoid a dependency on that module. Also, another private script which validates Build.PL and
Makefile.PL would complain about the missing dependency.

See L<the demo page|http://savage.net.au/Perl-modules/html/marpax.demo.stringparser/> for details.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/MarpaX-Demo-StringParser>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX::Demo::StringParser>.

=head1 Author

L<MarpaX::Demo::StringParser> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

Marpa's homepage: <http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
