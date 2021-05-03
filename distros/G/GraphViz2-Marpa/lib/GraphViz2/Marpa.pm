package GraphViz2::Marpa;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use GraphViz2::Marpa::Renderer::Graphviz;

use Log::Handler;

use Marpa::R2;

use Moo;

use Path::Tiny; # For path().

use Tree::DAG_Node;

use Types::Standard qw/Any ArrayRef Int HashRef Str/;

use Try::Tiny;

has bnf =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has bnf4html =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has brace_count =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
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
	default  => sub {return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has grammar4html =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Any,
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

has known_events =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
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

has output_file =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has recce =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has recce4html =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has renderer =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has stack =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has trace_terminals =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
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

our $VERSION = '2.12';

# ------------------------------------------------

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

# Input stuff.

:start					::= graph_definition

graph_definition		::= prolog_tokens graph_statement

# Prolog stuff.

prolog_tokens			::= prolog_strict_and_id
							| prolog_strict_no_id
							| prolog_no_strict_but_id
							| prolog_no_strict_no_id

prolog_strict_and_id	::= strict_token graph_type graph_id_token

prolog_strict_no_id		::= strict_token graph_type

prolog_no_strict_but_id	::= graph_type graph_id_token

prolog_no_strict_no_id	::= graph_type

strict_token			::= strict_literal

graph_type				::= digraph_literal
							| graph_literal

graph_id_token			::= node_name

# Graph stuff.

graph_statement			::= open_brace statement_list close_brace

statement_list			::= statement_token*

statement_token			::= statement statement_terminator

# Statement stuff.

statement				::= assignment_statement
							| node_statement
							| edge_statement
							| subgraph_statement

statement_terminator	::= semicolon_literal
statement_terminator	::=

# Assignment stuff.

assignment_statements	::= assignment_statement*

assignment_statement	::= attribute_name ('=') attribute_value

# Node stuff

node_statement			::= node_name attribute_statements

# Attribute stuff.

attribute_statements	::=  attribute_statement*

attribute_statement		::= open_bracket assignment_statements close_bracket

# Edge stuff

edge_statement			::= edge_lhs edge_rhs attribute_statements

edge_lhs				::= node_statement
							| subgraph_statement

edge_rhs				::= edge_name edge_lhs
							| edge_name edge_lhs edge_rhs

edge_name				::= directed_edge
							| undirected_edge

# Subgraph stuff.

subgraph_statement		::= subgraph_sequence attribute_statements

subgraph_sequence		::= subgraph_sub_and_id
							| subgraph_sub_no_id
							| subgraph_no_sub_no_id

subgraph_sub_and_id		::= subgraph_prefix subgraph_id_token graph_statement

subgraph_sub_no_id		::= subgraph_prefix graph_statement

subgraph_no_sub_no_id	::=	graph_statement

subgraph_prefix			::= subgraph_literal

subgraph_id_token		::= subgraph_id

# Lexemes in alphabetical order.
# Quoted string handling copied from Marpa::R2's metag.bnf.

:lexeme					~ attribute_name		pause => before		event => attribute_name
attribute_name			~ string

:lexeme					~ attribute_value		pause => before		event => attribute_value
attribute_value			~ string

:lexeme					~ close_brace			pause => before		event => close_brace
close_brace				~ '}'

:lexeme					~ close_bracket			pause => before		event => close_bracket
close_bracket			~ ']'
close_bracket			~ '];'

:lexeme					~ digraph_literal		pause => before		event => digraph_literal
digraph_literal			~ 'digraph':i

:lexeme					~ directed_edge			pause => before		event => directed_edge
directed_edge			~ '->'

double_quoted_char_set	~ double_quoted_char+
double_quoted_char		~ escaped_char
							|  [^\"\x{0A}\x{0B}\x{0C}\x{0D}\x{0085}\x{2028}\x{2029}]

escaped_char			~ '\' [[:print:]]

# Use ' here just for the UltraEdit syntax hiliter.

:lexeme					~ graph_literal			pause => before		event => graph_literal
graph_literal			~ 'graph':i

html_quoted_char_set	~ [.]+

:lexeme					~ node_name				pause => before		event => node_name
node_name				~ string

:lexeme					~ open_brace			pause => before		event => open_brace
open_brace				~ '{'

:lexeme					~ open_bracket			pause => before		event => open_bracket
open_bracket			~ '['

semicolon_literal		~ ';'

:lexeme					~ strict_literal		pause => before		event => strict_literal
strict_literal			~ 'strict':i

string					~ [\"]	double_quoted_char_set	[\"]
string					~ '<'	html_quoted_char_set	'>'
string					~ unquoted_char_set

:lexeme					~ subgraph_id			pause => before		event => subgraph_id
subgraph_id				~ string

:lexeme					~ subgraph_literal		pause => before		event => subgraph_literal
subgraph_literal		~ 'subgraph':i

:lexeme					~ undirected_edge		pause => before		event => undirected_edge
undirected_edge			~ '--'

# The '=' is necessary for cases like: 'name=value' in node_1 [name=value].

unquoted_char_set		~ unquoted_char+
unquoted_char			~ escaped_char
							| [^\s\[\]={}]

# Boilerplate.

:discard				~ separators
separators				~ [;,]

:discard				~ whitespace
whitespace				~ [\s]+

:discard				~ <C style comment>
:discard				~ <Cplusplus style comment>
:discard				~ <hash style comment>

# C and C++ comment handling copied from MarpaX::Languages::C::AST.

<C style comment>					~ '/*' <comment interior> '*/'

<comment interior>					~ <optional non stars> <optional star prefixed segments> <optional pre final stars>

<optional non stars>				~ [^*]*
<optional star prefixed segments>	~ <star prefixed segment>*
<star prefixed segment>				~ <stars> [^/*] <optional star free text>
<stars>								~ [*]+
<optional star free text>			~ [^*]*
<optional pre final stars>			~ [*]*

<Cplusplus style comment>			~ '//' <Cplusplus comment interior>
<Cplusplus comment interior>		~ [^\n]*

# Hash comment handling copied from Marpa::R2's metag.bnf.

<hash style comment>				~ <terminated hash comment>
										| <unterminated final hash comment>

<terminated hash comment>			~ '#' <hash comment body> <vertical space char>

<unterminated final hash comment>	~ '#' <hash comment body>

<hash comment body>					~ <hash comment char>*

<vertical space char>				~ [\x{0A}\x{0B}\x{0C}\x{0D}\x{2028}\x{2029}]

<hash comment char>					~ [^\x{0A}\x{0B}\x{0C}\x{0D}\x{2028}\x{2029}]

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
			grammar         => $self -> grammar,
			ranking_method  => 'high_rule_only',
			trace_terminals => $self -> trace_terminals,
		})
	);

	my(%event);

	for my $line (split(/\n/, $self -> bnf) )
	{
		$event{$1} = 1 if ($line =~ /event\s+=>\s+(\w+)/);
	}

	$self -> known_events(\%event);

	# This grammar was devised by rns (Ruslan Shvedov) for nested, double-quoted strings.
	# See MarpaX::Demo::SampleScipts and scripts/quoted.strings.05.pl.

	$self -> bnf4html
	(
<<'END_OF_GRAMMAR'
:default		::= action => [ values ]

lexeme default	= latm => 1

string			::= '<' quoted '>'
quoted			::= item | quoted item
item			::= string | unquoted

unquoted		~ [^<>]+

:discard		~ whitespace
whitespace		~ [\s+]
END_OF_GRAMMAR
	);

	$self -> grammar4html
	(
		Marpa::R2::Scanless::G -> new
		({
			source => \$self -> bnf4html
		})
	);

	# Since $self -> stack has not been initialized yet,
	# we can't call _add_daughter() until after this statement.

	$self -> tree(Tree::DAG_Node -> new({name => 'root', attributes => {name => 'root', port => '', type => 'root_literal', uid => $self -> uid, value => 'root'} }));
	$self -> stack([$self -> tree -> root]);

	for my $name (qw/prolog graph/)
	{
		$self -> _add_daughter($name, {type => "${name}_literal", value => $name});
	}

	# The 'prolog' daughter is the parent of all items in the prolog,
	# so it gets pushed onto the stack.
	# Later, when 'digraph' or 'graph' is encountered, the 'graph' daughter replaces it.

	my(@daughters) = $self -> tree -> daughters;
	my($index)     = 0; # 0 => prolog, 1 => graph.
	my($stack)     = $self -> stack;

	push @$stack, $daughters[$index];

	$self -> stack($stack);

} # End of BUILD.

# ------------------------------------------------

sub _add_daughter
{
	my($self, $name, $attributes)  = @_;
	my(@name)          = $self -> decode_port_compass($$attributes{value});
	$$attributes{name} = $name[0];
	$$attributes{port} = $name[1];
	$$attributes{uid}  = $self -> uid($self -> uid + 1);
	my($node)          = Tree::DAG_Node -> new({name => $name, attributes => $attributes});
	my($stack)         = $self -> stack;

	$$stack[$#$stack] -> add_daughter($node);

} # End of _add_daughter.

# ------------------------------------------------

sub _check4embedded_separator
{
	my($self, $lexeme, $pos) = @_;

	# Separators are [;,].
	# The grammar allows them in things, like:
	# o width=.1,height=.1.				Accept floats.
	# o fontsize=24,fontname="Arial".	Accept integers.
	# o color="slateblue",fontsize=24.	Accept "...".
	# o style=filled,color=white.		Accent [A-Za-z]

	my($numeric) = ($lexeme =~ /^(\d+|\d+\.\d*|\.\d+)[;,]/) ? $1 : undef;

	if (defined($numeric) || ($lexeme =~ /^(".*"|[A-Za-z]+)[;,]/s) )
	{
		my($s)  = $lexeme;
		$lexeme = $numeric || $1;
		$pos    = $pos - length($s) + length($lexeme);
	}

	return ($lexeme, $pos);

} # End of _check4embedded_separator.

# ------------------------------------------------

sub clean_after
{
	my($self, $s) = @_;

	# The grammar allows things like 'xyz,', so clean them up.
	# Also, trim spaces and then double-quotes. The reason for doing things in this order
	# is that the user might have written "  X  ", so we don't remove the quotes first.

	substr($s, -1, 1) = '' if (substr($s, -1, 1) eq ',');
	$s                =~ s/^\s+//;
	$s                =~ s/\s+$//;
	$s                =~ s/"(.*)"/$1/;

	return $s;

} # End of clean_after.

# ------------------------------------------------

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

# ------------------------------------------------

sub decode_node
{
	my($self, $node) = @_;
	my($attributes)  = $node -> attributes;

	return
	{
		id    => $node -> name,
		name  => $$attributes{name},
		port  => $$attributes{port},
		type  => $$attributes{type},
		uid   => $$attributes{uid},
		value => $$attributes{value},
	};

} # End of decode_node.

# --------------------------------------------------

sub decode_port_compass
{
	my($self, $name) = @_;

	# Remove :port:compass, if any, from name.
	# But beware Perl-style node names like 'A::Class'.
	# The (?=.) means there must be something after the last ':',
	# which means we don't split 'A:' or 'A::'.

	my(@field) = split(/(:(?!:)(?=.))/, $name);
	$field[0]  = $name if ($#field < 0);

	# Restore Perl module names:
	# o A: & : & B to A::B.
	# o A: & : B: & : & C to A::B::C.

	while ( ($field[0] =~ /:$/) && ($#field >= 2) )
	{
		splice(@field, 0, 3, "$field[0]:$field[2]");
	}

	# Restore:
	# o : & port to :port.
	# o : & port & : & compass to :port:compass.

	splice(@field, 1, $#field, join('', @field[1 .. $#field]) ) if ($#field > 0);

	my(@result);

	if ($#field == 0)
	{
		@result = ($name, '');
	}
	else
	{
		@result = ($field[0], join('', @field[1 .. $#field]) );
	}

	return @result;

} # End of decode_port_compass.

# ------------------------------------------------

sub decode_tree
{
	my($self, $tree) = @_;
	my($prolog) =
	{
		digraph => 'digraph',
		strict  => '',
	};

	# Examine the daughters of the prolog to find the digraph/graph and strict attributes.

	my($node_id);

	for my $node ( ($tree -> daughters)[0] -> daughters)
	{
		$node_id          = $self -> decode_node($node);
		$$prolog{digraph} = 'graph'   if ($$node_id{name} eq 'graph');
		$$prolog{strict}  = 'strict ' if ($$node_id{name} eq 'strict');
	}

	return $prolog;

} # End of decode_tree.

# ------------------------------------------------

sub _decode_result
{
	my($self, $result) = @_;
	my(@worklist)      = $result;

	my($obj);
	my($ref_type);
	my(@stack);

	do
	{
		$obj      = shift @worklist;
		$ref_type = ref $obj;

		if ($ref_type eq 'ARRAY')
		{
			unshift @worklist, @$obj;
		}
		elsif ($ref_type eq 'HASH')
		{
			push @stack, {%$obj};
		}
		elsif ($ref_type)
		{
			die "Unsupported object type $ref_type\n";
		}
		else
		{
			push @stack, $obj;
		}

	} while (@worklist);

	return join('', @stack);

} # End of _decode_result.

# ------------------------------------------------

sub _dump_stack
{
	my($self, $caller) = @_;

	$self -> log(info => "\tStack @ $caller");

	my($node_id);

	for my $item (@{$self -> stack})
	{
		$node_id = $self -> decode_node($item);

		$self -> log(info => "\tUid: $$node_id{uid}. Id: $$node_id{id}. Name: $$node_id{name}");
	}

	$self -> log(debug => join("\n", @{$self -> tree -> tree2string}) );

} # End of _dump_stack.

# ------------------------------------------------

sub hashref2string
{
	my($self, $hashref) = @_;
	$hashref ||= {};

	return '{' . join(', ', map{qq|$_ => "$$hashref{$_}"|} sort keys %$hashref) . '}';

} # End of hashref2string.

# ------------------------------------------------

sub _identify_lexeme
{
	my($self, $string, $start, $span, $pos, $lexeme) = @_;

	pos($string) = $start + $span;
	$string      =~ /\G\s*(\S)/ || return;
	my($literal) = $1;

	my($type);

	if (substr($lexeme, 0, 1) eq '{')
	{
		$pos++;

		$span = 1;
		$type = 'open_brace';
	}
	else
	{
		$type = ($literal eq '=') ? 'attribute_name' : 'node_name';
	}

	$self -> log(debug => "Disambiguated lexeme (2 of 2) |$lexeme| as '$type'. pos: $pos");

	return ($type, $span, $pos);

} # End of _identify_lexeme.

# ------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> log($level => $s) if ($self -> logger);

} # End of log.

# ------------------------------------------------

sub next_few_chars
{
	my($self, $s, $offset) = @_;
	$s = substr($s, $offset, 20);
	$s =~ tr/\n/ /;
	$s =~ s/^\s+//;
	$s =~ s/\s+$//;

	return $s;

} # End of next_few_chars.

# ------------------------------------------------

sub _process
{
	my($self)          = @_;
	my($string)        = $self -> clean_before($self -> graph_text);
	my($length)        = length $string;
	my($format)        = '%-20s    %5s    %5s    %5s    %-20s    %-20s';
	my($last_event)    = '';
	my($prolog_token)  = qr/^(?:digraph|graph|strict)_literal$/;
	my($pos)           = 0;
	my(%class)         =
	(
		edge  => 'class',
		graph => 'class',
		node  => 'class',
	);

	$self -> log(debug => "Length of input: $length");
	$self -> log(debug => sprintf($format, 'Event', 'Start', 'Span', 'Pos', 'Lexeme', 'Comment') );

	my($event_name);
	my(@fields);
	my($lexeme);
	my($node_name);
	my($original_lexeme);
	my($span, $start, $s, $stack);
	my($temp, $type);

	# We use read()/lexeme_read()/resume() because we pause at each lexeme.
	# Also, in read(), we use $pos and $length to avoid reading Ruby Slippers tokens (if any).

	for
	(
		$pos = $self -> recce -> read(\$string, $pos, $length);
		$pos < $length;
		$pos = $self -> recce -> resume($pos)
	)
	{
		($start, $span)            = $self -> recce -> pause_span;
		($event_name, $span, $pos) = $self -> _validate_event($string, $start, $span, $pos);
		$lexeme                    = $self -> recce -> literal($start, $span);
		$original_lexeme           = $lexeme;
		$pos                       = $self -> recce -> lexeme_read($event_name);

		die "lexeme_read($event_name) rejected lexeme |$lexeme|\n" if (! defined $pos);

		# Special case.
		# This 'if' matches the start of the big 'if' just below.
		# It's here so that the log(debug) code is in the right order.

		if ( ($event_name eq 'attribute_name') && (substr($lexeme, 0, 1) eq '[') )
		{
			$temp = '[';

			$self -> log(debug => sprintf($format, 'open_bracket', $start, 1, $pos, $temp, '-') );
			$self -> _process_bracket($temp, 'open_bracket');
		}

		$self -> log(debug => sprintf($format, $event_name, $start, $span, $pos, $lexeme, '-') );

		if ($event_name eq 'attribute_name')
		{
			# Special cases.

			if (substr($lexeme, 0, 1) eq '[')
			{
				$event_name           = 'open_bracket'; # Sets $last_event at the end of the loop.
				substr($lexeme, 0, 1) = '';
			}

			$fields[0] = $self -> clean_after($lexeme);
		}
		elsif ($event_name eq 'attribute_value')
		{
			if ($lexeme =~ /^</)
			{
				# Note: We pass in $start and it becomes $pos.

				($lexeme, $pos) = $self -> _process_html(\$string, $start);

				$self -> _add_daughter('attribute', {type => $fields[0], value => $lexeme});
			}
			else
			{
				# Special cases.
				# Handle ']' and '];'.

				$temp                  = '';
				substr($lexeme, -1, 1) = '' if (substr($lexeme, -1, 1) eq ';');

				if (substr($lexeme, -1, 1) eq ']')
				{
					$temp                  = ']';
					substr($lexeme, -1, 1) = '';
				}

				($lexeme, $pos) = $self -> _check4embedded_separator($lexeme, $pos);
				$lexeme         = $self -> clean_after($lexeme);
				$s              = $self -> next_few_chars($string, $pos);

				$self -> log(debug => "Lexeme |$original_lexeme| corrected to be |$lexeme|. pos: $pos. Next few char |$s|") if ($original_lexeme ne $lexeme);
				$self -> _add_daughter('attribute', {type => $fields[0], value => $lexeme});

				@fields = ();

				if ($temp)
				{
					$event_name = 'close_bracket'; # Sets $last_event at the end of the loop.

					$self -> log(debug => sprintf($format, $event_name, $start, 1, $pos, $temp, 'Adjusted event_name') );
					$self -> _process_bracket($temp, $event_name);
				}
			}
		}
		elsif ($event_name eq 'close_brace')
		{
			$self -> _process_brace($lexeme, $event_name);
		}
		elsif ($event_name eq 'close_bracket')
		{
			# Special case.

			substr($lexeme, -1, 1) = '' if (substr($lexeme, -1, 1) eq ';');
			$s                     = $self -> next_few_chars($string, $pos);

			$self -> log(debug => "Lexeme |$original_lexeme| corrected to be |$lexeme|. pos: $pos. Next few char |$s|") if ($original_lexeme ne $lexeme);
			$self -> _process_bracket($lexeme, $event_name);
		}
		elsif ($event_name eq 'directed_edge')
		{
			$self -> _add_daughter('edge_id', {type => $event_name, value => $lexeme});
		}
		elsif ($event_name eq 'node_name')
		{
			# Special cases.

			if (substr($lexeme, 0, 1) eq '{')
			{
				$event_name = 'open_brace';
				$pos        -= (length($lexeme) - 1);
				$lexeme     = '{';

				$self -> log(debug => sprintf($format, $event_name, $start, $span, $pos, $lexeme, 'Adjusted event_name, lexeme and pos') );
				$self -> _process_brace($lexeme, $event_name);

				next;
			}

			# This 'if' is repeated just below.

			if (substr($lexeme, -1, 1) eq ';')
			{
				substr($lexeme, -1, 1) = '';

				next if ($lexeme eq '');
			}

			if (substr($lexeme, -1, 1) eq '}')
			{
				substr($lexeme, -1, 1) = '';
				$pos                   -= 1;
			}

			# This 'if' is repeated just above.

			if (substr($lexeme, -1, 1) eq ';')
			{
				substr($lexeme, -1, 1) = '';

				next if ($lexeme eq '');
			}

			$self -> log(debug => "Lexeme |$original_lexeme| corrected to be |$lexeme|") if ($original_lexeme ne $lexeme);

			$lexeme = $self -> clean_after($lexeme);

			if ($class{lc $lexeme})
			{
				$lexeme = lc $lexeme;
				$type   = $class{$lexeme};
			}
			else
			{
				$type = 'node_id';

				# If this node's mother is the 'graph' node, then it's a graph_id.

				$stack = $self -> stack;
				$type  = 'graph_id' if ($$stack[$#$stack] -> name eq 'graph');
			}

			$self -> log(debug => "|$lexeme| classified as a $type") if ($original_lexeme ne $lexeme);
			$self -> _add_daughter($type, {type => $type, value => $lexeme});
		}
		elsif ($event_name eq 'open_brace')
		{
			$self -> _process_brace($lexeme, $event_name);
		}
		elsif ($event_name eq 'open_bracket')
		{
			$self -> _process_bracket($lexeme, $event_name);
		}
		elsif ($event_name =~ $prolog_token)
		{
			$self -> _process_prolog_token($event_name, $lexeme);
		}
		elsif ($event_name eq 'subgraph_id')
		{
			$self -> _add_daughter('subgraph_id', {type => $event_name, value => $lexeme});
		}
		elsif ($event_name eq 'subgraph_literal')
		{
			$self -> _add_daughter('literal', {type => $event_name, value => 'subgraph'});
		}
		elsif ($event_name eq 'undirected_edge')
		{
			$self -> _add_daughter('edge_id', {type => $event_name, value => $lexeme});
		}

		# Step past separators.

		if (substr($string, $pos, 1) =~ /[;,]/)
		{
			$pos++;
		}

		$last_event = $event_name;
    }

	if (my $ambiguous_status = $self -> recce -> ambiguous)
	{
		my($terminals) = $self -> recce -> terminals_expected;
		$terminals     = ['(None)'] if ($#$terminals < 0);

		$self -> log(info => 'Terminals expected: ' . join(', ', @$terminals) );
		$self -> log(info => "Parse is ambiguous. Status: $ambiguous_status");
	}

	# Return a defined value for success and undef for failure.

	return $self -> recce -> value;

} # End of _process.

# ------------------------------------------------

sub _process_brace
{
	my($self, $name, $event_name) = @_;

	# When the 1st '{' is encountered, the 'graph' daughter of the root
	# becomes the parent of all other tree nodes, replacing the 'prolog' daughter,
	# which has been the parent of 'strict' and 'digraph' or graph' up to now.

	if ($self -> brace_count == 0)
	{
		my($stack) = $self -> stack;

		pop @$stack;

		my(@daughters) = $self -> tree -> daughters;
		my($index)     = 1; # 0 => prolog, 1 => graph.

		push @$stack, $daughters[$index];

		$self -> stack($stack);
	}

	# When a '{' is encountered, the last thing pushed becomes it's parent.
	# Likewise, when a '}' is encountered, we pop the stack.

	my($stack) = $self -> stack;

	if ($name eq '{')
	{
		$self -> brace_count($self -> brace_count + 1);
		$self -> _add_daughter('literal', {type => $event_name, value => $name});

		my(@daughters) = $$stack[$#$stack] -> daughters;

		push @$stack, $daughters[$#daughters];

		$self -> stack($stack);
	}
	else
	{
		pop @$stack;

		$self -> stack($stack);
		$self -> _add_daughter('literal', {type => $event_name, value => $name});
		$self -> brace_count($self -> brace_count - 1);
	}

} # End of _process_brace.

# ------------------------------------------------

sub _process_bracket
{
	my($self, $name, $event_name) = @_;

	# When a '[' is encountered, the last thing pushed becomes it's parent.
	# Likewise, if ']' is encountered, we pop the stack.

	my($stack) = $self -> stack;

	if ($name eq '[')
	{
		my(@daughters) = $$stack[$#$stack] -> daughters;

		push @$stack, $daughters[$#daughters];

		$self -> _add_daughter('literal', {type => $event_name, value => $name});
	}
	else
	{
		$self -> _add_daughter('literal', {type => $event_name, value => $name});

		pop @$stack;

		$self -> stack($stack);
	}

} # End of _process_bracket.

# ------------------------------------------------

sub _process_html
{
	my($self, $stringref, $pos) = @_;

	$self -> recce4html
	(
		Marpa::R2::Scanless::R -> new
		({
			grammar => $self -> grammar4html,
		})
	);

	# Return 0 for success and 1 for failure.

	my($candidate) = substr($$stringref, $pos);

	my($error);
	my($html);
	my($value);

	try
	{
		$self -> recce4html -> read(\$candidate);

		$value = $self -> recce4html -> value;

		if (defined $value)
		{
			$html = $self -> _decode_result($$value);
		}
		else
		{
			$error = 'Parse failed';
		}
	}
	catch
	{
		$error = $_;

		# But wait! It might be OK after all.
		# Actually, this branch always happens, because for valid DOT files,
		# there must be something in the input ('lexemes') after the HTML.

		if ($self -> recce4html -> exhausted)
		{
			my(@span) = $self -> recce4html -> last_completed_span('string');
			$html     = substr($candidate, $span[0], $span[1]);
		}
	};

	if (! defined $html)
	{
		die $error;
	}

	$pos += length($html);

	return ($html, $pos);

} # End of _process_html.

# ------------------------------------------------

sub _process_prolog_token
{
	my($self, $event_name, $value) = @_;

	$self -> _add_daughter('literal', {type => $event_name, value => lc $value});

	# When 'digraph' or 'graph' is encountered, the 'graph' daughter of the root
	# becomes the parent of all other tree nodes, replacing the 'prolog' daughter.

	if ($event_name ne 'strict_literal')
	{
		my($stack) = $self -> stack;

		pop @$stack;

		my(@daughters) = $self -> tree -> daughters;
		my($index)     = 1; # 0 => prolog, 1 => graph.

		push @$stack, $daughters[$index];

		$self -> stack($stack);
	}

} # End of _process_prolog_token.

# ------------------------------------------------

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
		# In the regexp, # is written as \# just for the Ultraedit syntax hiliter.
		# Steps:
		# o Read file as a set of lines.
		# o Look for trailing \ chars, and combine those lines.
		# o Combine all remaining lines with ' '.

		my(@line)   = grep{! m!^(?:\#|//)!} path($self -> input_file) -> lines_utf8;
		my($last)   = $#line; # Store this separately so we can fiddle $i.
		my($i)      = 0;
		my($buffer) = '';

		my(@out);

		# We don't check the very last line. If it ends with '\\', we definitely want an error.

		while ($i < $last)
		{
			if ($line[$i] =~ /(.*)\\$/)
			{
				$buffer .= $1;
			}
			else
			{
				if (length($buffer) > 0)
				{
					$line[$i] = "$buffer$line[$i]";
					$buffer   = '';
				}

				push @out, $line[$i];
			}

			$i++;
		}

		push @out, $line[$i];

		$self -> graph_text(join(' ', @out) );

		$self -> log(debug => "After processing this graph:\n|" . $self -> graph_text . '|');
	}
	else
	{
		die "You must provide a graph using one of -input_file or -description. \n";
	}

	# Return 0 for success and 1 for failure.

	my($result) = 0;

	try
	{
		if (defined (my $value = $self -> _process) )
		{
			$self -> log(info => 'Parsed tree:');
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

	$self -> log(info => "Parse result:  $result (0 is success)");

	if ($result == 0)
	{
		# Clean up the stack by popping the root node.

		my($stack) = $self -> stack;

		pop @$stack;

		$self -> stack($stack);
		$self -> log(debug => 'Brace count:   ' . $self -> brace_count . ' (0 is success)');
		$self -> log(debug => 'Stack size:    ' . $#{$self -> stack} . ' (0 is success)');

		my($output_file) = $self -> output_file;

		if ($output_file)
		{
			$self -> renderer
			(
				GraphViz2::Marpa::Renderer::Graphviz -> new
				(
					logger      => $self -> logger,
					maxlevel    => $self -> maxlevel,
					minlevel    => $self -> minlevel,
					output_file => $self -> output_file,
					tree        => $self -> tree,
				)
			) if (! $self -> renderer);

			$self -> renderer -> run;
		}
	}
	else
	{
		$self -> log(info => 'The stack and the tree when we died ...');
		$self -> _dump_stack('_process_brace() pushed { onto stack');
	}

	# Return 0 for success and 1 for failure.

	return $result;

} # End of run.

# ------------------------------------------------

sub _validate_event
{
	my($self, $string, $start, $span, $pos) = @_;
	my(@event)         = @{$self -> recce -> events};
	my($event_count)   = scalar @event;
	my(@event_name)    = sort map{$$_[0]} @event;
	my($event_name)    = $event_name[0]; # Default.
	my($lexeme)        = substr($string, $start, $span);
	my($line, $column) = $self -> recce -> line_column($start);
	my($literal)       = $self -> next_few_chars($string, $start + $span);
	my($message)       = "Location: ($line, $column). Lexeme: |$lexeme|. Next few chars: |$literal|";
	$message           = "$message. Events: $event_count. Names: ";

	$self -> log(debug => $message . join(', ', @event_name) . '.');

	my(%event_name);

	@event_name{@event_name} = (1) x @event_name;

	for (@event_name)
	{
		die "Unexpected event name '$_'" if (! ${$self -> known_events}{$_});
	}

	if ($event_count > 1)
	{
		my(%special_case) =
		(
			'}'        => 'close_brace',
			']'        => 'close_bracket',
			'];'       => 'close_bracket',
			'->'       => 'directed_edge',
			'{'        => 'open_brace',
			'['        => 'open_bracket',
			'subgraph' => 'subgraph_literal',
			'--'       => 'undirected_edge',
		);

		if ($special_case{$lexeme})
		{
			$event_name = $special_case{$lexeme};

			$self -> log(debug => "Disambiguated lexeme (1 of 2) |$lexeme| as '$event_name'");
		}
		elsif ($event_count == 2)
		{
			# We can handle ambiguous events when they are 'attribute_name' and 'node_name'.
			# 'attribute_name' is followed by '=', and 'node_name' is followed by anything else.
			# In fact, 'node_name' may be folowed by '[' to indicate the start of its attributes.

			$event_name   = undef;
			my($expected) = "$event_name[0]!$event_name[1]";

			if ($expected eq 'attribute_name!node_name')
			{
				($event_name, $span, $pos) = $self -> _identify_lexeme($string, $start, $span, $pos, $lexeme);
			}

			if (! defined $event_name)
			{
				die "Cannot identify lexeme as either 'attribute_name' or 'node_name'. \n";
			}
		}
		else
		{
			die "The code only handles 1 event at a time, or the pair ('attribute_name', 'node_name'). \n";
		}
	}

	return ($event_name, $span, $pos);

} # End of _validate_event.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<GraphViz2::Marpa> - A Marpa-based parser for Graphviz C<dot> files

=head1 Synopsis

=over 4

=item o Display help

	perl scripts/g2m.pl -h

=item o Run the parser

	perl scripts/g2m.pl -input_file data/16.gv
	perl scripts/g2m.pl -input_file data/16.gv -max info

The L</FAQ> discusses the way the parsed data is stored in RAM.

=item o Run the parser and the default renderer

	perl scripts/g2m.pl -input_file data/16.gv -output_file ./16.gv

./16.gv will be the rendered Graphviz C<dot> file.

See scripts/test.utf8.sh for comparing the output of running the parser, and C<dot>, on all
data/utf8.*.gv files.

=back

See also L</Scripts>.

=head1 Description

L<GraphViz2::Marpa> provides a L<Marpa::R2>-based parser for L<Graphviz|http://www.graphviz.org/>
graph definitions.

Demo output: L<http://savage.net.au/Perl-modules/html/graphviz2.marpa/index.html>.

L<Marpa's homepage|http://savage.net.au/Marpa.html>.

Articles:

=over 4

=item o Overview

L<Announcing this module|http://savage.net.au/Ron/html/A.New.Marpa-based.Parser.for.GraphViz.html>

=item o Building the Grammar

L<Conditional preservation of whitespace|http://savage.net.au/Ron/html/Conditional.preservation.of.whitespace.html>

This module will be re-written, again, now that its BNF has been incorporated into GraphViz2::Marpa,
and patched along the way.

=back

=head1 Modules

=over 4

=item o L<GraphViz2::Marpa>

The current module, which documents the set of modules.

It can, optionally, use the default renderer L<GraphViz2::Marpa::Renderer::Graphviz>.

Accepts a L<Graphviz|http://www.graphviz.org/> graph definition and builds a corresponding
data structure representing the parsed graph. It can pass that data to the default renderer,
L<GraphViz2::Marpa::Renderer::Graphviz>, which can then render it to a text file ready to be
input to C<dot>. Such 'round-tripping', as it's called, is the best way to test a renderer.

See scripts/g2m.pl and scripts/test.utf8.sh.

=item o L<GraphViz2::Marpa::Renderer::Graphviz>

The default renderer. Optionally called by the parser.

=item o L<GraphViz2::Marpa::Config>

Auxiliary code, used to help generate the demo page.

=item o L<GraphViz2::Marpa::Utils>

Auxiliary code, used to help generate the demo page.

=back

=head1 Sample Data

=over 4

=item o Input files: data/*.gv

These are valid L<Graphviz|http://www.graphviz.org/> graph definition files.

Some data/*.gv files may contain deliberate mistakes, which may or may not stop production
of output files. They may cause various warning messages to be printed by C<dot> when
being rendered.

See L<the demo page|http://savage.net.au/Perl-modules/html/graphviz2.marpa/index.html> for details.

=item o Output files: html/*.svg

The html/*.svg are L<Graphviz|http://www.graphviz.org/> graph definition files output
by scripts/generate.demo.sh.

The round trip shows that the lex/parse process does not lose information along the way, but
comments are discarded..

This set, and the set xt/author/html/*.svg just below, are generated by running
scripts/generate.demo.sh. This in turn runs both scripts/generate.svg.sh and
scripts/generate.demo.pl.

=item o Input files: xt/author/data/*.gv

As for data/*.gv above, but these files are copied from Graphviz V 2.38.0, and are often quite
complex.

See find.candidates.pl, below.

=item o Output files: xt/author/html/*.svg

As for html/*.svg above.

=back

=head1 Scripts

These are in the scripts/ directory.

=over 4

=item o copy.config.pl

For use by the author. Output:

	Copied config/.htgraphviz2.marpa.conf to /home/ron/.config/Perl/GraphViz2-Marpa

=item o find.candidates.pl

For use by the author.

This scans an unpacked distro of Graphviz V 2.38.0 and finds *.gv matching these criteria:

=over 4

=item o In ~/Downloads/Graphviz/graphviz-2.38.0/

=item o Not too big

I.e. the file must be < 10,000 bytes in size, otherwise it may take too long to process.

=item o Not a fake

Currently, only ~/Downloads/Graphviz/graphviz-2.38.0/tclpkg/gv/META.gv fits this
definition.

=item o Not already present in xt/author/data

=back

Any candidates found have their names printed, for easy one-at-a-time copying from Graphviz and
testing via scripts/test.1.sh.

=item o find.config.pl

For use by the author. Output:

	Using: File::HomeDir -> my_dist_config('GraphViz2-Marpa', '.htgraphviz2.marpa.conf'):
	Found: /home/ron/.config/Perl/GraphViz2-Marpa/.htgraphviz2.marpa.conf

=item o g2m.pl

Runs the parser. Try running with -h.

=item o g2m.sh

Simplifies running g2m.pl.

=item o generate.demo.pl

See generate.demo.sh.

=item o generate.demo.sh

For use by the author. Actions:

=over

=item o Runs dot on all data/*.gv files; outputs to html/*.svg

=item o Runs scripts/generate.demo.pl; outputs to html/index.html

=item o Copies html/* to various places

=back

=item o generate.svg.sh

Convert all data/*.svg into html/*.svg.

Used by generate.demo.sh.

=item o gv2svg.sh

Converts one data/*.gv file into $DR/Perl-modules/html/graphviz2.marpa/*.svg.

=item o pod2html.sh

Converts all *.pm files to *.html, and copies them in my web server's dir structure (in Debian's
RAM disk).

=item o test.1.sh

Runs both the parser and C<dot> so I can compare the output.

=item o test.html.pl

Uses method perform_1_test() in L<GraphViz2::Marpa::Utils>, to test the stand-alone BNF used for
HTML-like tables.

Note: t/test.t also calls perform_1_test().

=item o test.utf8.sh

Tests one data/utf8*.gv file more thoroughly than test.1.sh does.

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<GraphViz2::Marpa> as you would for any C<Perl> module:

Run:

	cpanm GraphViz2::Marpa

or run:

	sudo cpan GraphViz2::Marpa

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

=head1 Constructor and Initialization

C<new()> is called as C<< my($g2m) = GraphViz2::Marpa -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2::Marpa>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</description([$graph])>]):

=over 4

=item o description => $graphDescription

Read the L<Graphviz|http://www.graphviz.org/> graph definition from the command line.

You are strongly encouraged to surround this string with '...' to protect it from your shell.

See also the 'input_file' option to read the description from a file.

The 'description' option takes precedence over the 'input_file' option.

Default: ''.

=item o input_file => $aDotInputFileName

Read the L<Graphviz|http://www.graphviz.org/> graph definition from a file.

See also the 'description' option to read the graph definition from the command line.

The 'description' option takes precedence over the 'input_file' option.

Default: ''.

See the distro for data/*.gv.

=item o logger => $aLoggerObject

Specify a logger compatible with L<Log::Handler>, for the lexer and parser to use.

Default: A logger of type L<Log::Handler> which writes to the screen.

To disable logging, just set 'logger' to the empty string (not undef).

=item o maxlevel => $logOption1

This option affects L<Log::Handler>.

See the L<Log::Handler::Levels> docs.

Default: 'notice'.

=item o minlevel => $logOption2

This option affects L<Log::Handler>.

See the L<Log::Handler::Levels> docs.

Default: 'error'.

No lower levels are used.

=item o output_file => aRenderedDotInputFileName

Specify the name of a file for the renderer to write.

That is, write the DOT-style graph definition to a file.

When this file and the input file are both run thru C<dot>, they should produce identical *.svg
files.

If an output file name is specified, an object of type L<GraphViz2::Marpa::Renderer::Graphviz> is
created and called after the input file has been successfully parsed.

Default: ''.

The default means the renderer is not called.

=item o renderer => aGraphViz2::Marpa::Renderer::Graphviz-compatible object

Specify a renderer for the parser to use.

See C<output_file> just above.

Default: undef.

If an output file is specified, then an object of type L<GraphViz2::Marpa::Renderer::Graphviz>
is created and its C<run()> method is called.

=item o trace_terminals => $Boolean

This allows g2m.pl to control the C<trace_terminals> setting passed to L<Marpa::R2::Scanless::R>.

=back

=head1 Methods

=head2 clean_before($s)

Clean the given string before passing it to Marpa.

=head2 clean_after($s)

Clean the given string before storing it in the tree.

=head2 decode_port_compass($name)

Returns a 2-element array for the given DOT node name.

=over 4

=item o [0]: The node name without any port+compass suffix

=item o [1]: The port+compass suffix (prefixed by ':'), or ''

=back

=head2 decode_node($node)

Returns a hashref of the tree node's name and attributes.

Key => Value pairs:

=over 4

=item o id => $node -> name

This identifies the type of tree node. It has values like 'node_id', 'edge_id', 'literal', etc.
These values come from the grammar.

=item o name => $$attributes{value}

This is the name of the tree node. The value comes from the input stream.

But, if C<id> is 'node_id', then C<name> is the DOT node's name without any port+compass suffix.

=item o port => The DOT node name's port+compass suffix (prefixed by ':'), or ''

This value come from the grammar.

=item o type => $$attributes{type}

This has values like 'node_id', 'open_bracket', etc. In fact, these are the names of lexemes.
These values come from the grammar.

=item o uid  => $$attributes{uid}

This is the unique uid of the tree node.

=item o value  => $$attributes{value}

This is usually a copy of the C<name> attribute. The value comes from the input stream.

If the C<id> is 'node_id>' then this value will be the DOT node's name including any
port+compass suffix.

=back

=head2 decode_tree($tree)

Returns a hashref of the tree's digraph/graph and strict attributes. These are extracted from the
prolog of the tree, which means $tree must be a whole tree, and not just a node within a whole
tree.

Key => Value pairs:

=over 4

=item o digraph => 'digraph' || 'graph'

Default: 'digraph'.

=item o strict  => 'strict' || '' (empty string)

Default: ''.

=back

=head2 description([$graph])

The [] indicate an optional parameter.

Get or set the L<Graphviz|http://www.graphviz.org/> graph definition string.

The value supplied by the 'description' option takes precedence over the value read from the
'input_file'.

See also L</input_file()>.

'description' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 hashref2string($h)

Convert the keys and values of $h to a string, including '{' and '}'.

Defaults to '{}' if $h is not defined.

=head2 input_file([$graph_file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file to read the L<Graphviz|http://www.graphviz.org/> graph
definition from.

The value supplied by the 'description' option takes precedence over the value read from the
'input_file'.

See also the L</description()> method.

'input_file' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 log($level, $s)

If a logger is defined, this logs the message $s at level $level.

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set 'logger' to the empty string (not undef), in the call to L</new()>.

This logger is passed to other modules.

'logger' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 maxlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is ceated.
See L<Log::Handler::Levels>.

'maxlevel' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 minlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created.
See L<Log::Handler::Levels>.

'minlevel' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.

=head2 next_few_chars($s, $offset)

Returns a substring of $s, starting at $offset, for use in progress messages.

The default string length returned is 20 characters.

=head2 output_file([$file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file for the renderer to write.

If an output file name is specified, an object of type L<GraphViz2::Marpa::Renderer::Graphviz> is
created and called after the input file has been successfully parsed.

'output_file' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 renderer([$renderer_object])

Here, the [] indicate an optional parameter.

Get or set the renderer object.

This renderer is called if C<output_file()> is given a value.

'renderer' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 run()

This is the only method the caller needs to call. All parameters are supplied to L</new()>
(or via other methods before C<run()> is called).

See scripts/g2m.pl.

Returns 0 for success and 1 for failure.

=head2 trace_terminals([$Boolean])

Here, the [] indicate an optional parameter.

Get or set the C<trace_terminals> option passed to L<Marpa::R2::Scanless::R>.

=head1 FAQ

=head2 How is the parsed data held in RAM?

The parsed output is held in a tree managed by L<Tree::DAG_Node>.

Here and below, the word C<node> (usually) refers to nodes in this tree, not Graphviz-style nodes.

The root node always looks like this when printed by Tree::DAG_Node's tree2string() method:

	root. Attributes: {node=>"root", port=>"", type=>"root_literal", uid=>"0", value=>"root"}

Interpretation:

=over 4

=item o The node name

Here, C<root>.

=item o The node's attributes

Key fields:

=over 4

=item o node

The name of the DOT node without any port+compass suffix. Here C<root>.

=item o port

The port+compass suffix of the DOT node name, if any, else ''. Here the empty string.

=item o type

Here, C<root_literal>.

The type (or name) of the value. The word 'name' is not used to avoid confusion with the name of the
node.

=item o uid

A unique integer assigned to each node. Counts up from 0. Not used.

=item o value

The value of the node.

Here, C<root>.

=back

=back

=head2 Can you explain this tree in more detail?

Sure.  Firstly, we examine a sample graph, assuming the module's pre-reqs are installed.
Let's use data/10.gv. Here it is as an
L<svg|http://savage.net.au/Perl-modules/html/graphviz2.marpa/10.svg>.

Run one of these:

	scripts/g2m.sh data/10.gv -max info
	perl -Ilib scripts/g2m.pl -input_file data/10.gv -max info

The former echos the input file to STDOUT before running the latter.

Using C<-max notice>, which is the default, produces no output from C<g2m.pl>.

This is the input:

	STRICT DiGraph graph_10_01
	{
		node_10_01_1 [fillcolor = red, style = filled]
		node_10_01_2 [fillcolor = green, style = filled]

		node_10_01_1 -> node_10_01_2 [arrowtail = dot, arrowhead = odot]
	}

And this is the output:

	Parsed tree:
	root. Attributes: {name => "root", port => "", type => "root_literal", uid => "0", value => "root"}
	   |--- prolog. Attributes: {name => "prolog", port => "", type => "prolog_literal", uid => "1", value => "prolog"}
	   |   |--- literal. Attributes: {name => "strict", port => "", type => "strict_literal", uid => "3", value => "strict"}
	   |   |--- literal. Attributes: {name => "digraph", port => "", type => "digraph_literal", uid => "4", value => "digraph"}
	   |--- graph. Attributes: {name => "graph", port => "", type => "graph_literal", uid => "2", value => "graph"}
	       |--- graph_id. Attributes: {name => "graph_10_01", port => "", type => "graph_id", uid => "5", value => "graph_10_01"}
	       |--- literal. Attributes: {name => "{", port => "", type => "open_brace", uid => "6", value => "{"}
	       |   |--- node_id. Attributes: {name => "node_10_01_1", port => "", type => "node_id", uid => "7", value => "node_10_01_1"}
	       |   |   |--- literal. Attributes: {name => "[", port => "", type => "open_bracket", uid => "8", value => "["}
	       |   |   |--- attribute. Attributes: {name => "red", port => "", type => "fillcolor", uid => "9", value => "red"}
	       |   |   |--- attribute. Attributes: {name => "filled", port => "", type => "style", uid => "10", value => "filled"}
	       |   |   |--- literal. Attributes: {name => "]", port => "", type => "close_bracket", uid => "11", value => "]"}
	       |   |--- node_id. Attributes: {name => "node_10_01_2", port => "", type => "node_id", uid => "12", value => "node_10_01_2"}
	       |   |   |--- literal. Attributes: {name => "[", port => "", type => "open_bracket", uid => "13", value => "["}
	       |   |   |--- attribute. Attributes: {name => "green", port => "", type => "fillcolor", uid => "14", value => "green"}
	       |   |   |--- attribute. Attributes: {name => "filled", port => "", type => "style", uid => "15", value => "filled"}
	       |   |   |--- literal. Attributes: {name => "]", port => "", type => "close_bracket", uid => "16", value => "]"}
	       |   |--- node_id. Attributes: {name => "node_10_01_1", port => "", type => "node_id", uid => "17", value => "node_10_01_1"}
	       |   |--- edge_id. Attributes: {name => "->", port => "", type => "directed_edge", uid => "18", value => "->"}
	       |   |--- node_id. Attributes: {name => "node_10_01_2", port => "", type => "node_id", uid => "19", value => "node_10_01_2"}
	       |       |--- literal. Attributes: {name => "[", port => "", type => "open_bracket", uid => "20", value => "["}
	       |       |--- attribute. Attributes: {name => "dot", port => "", type => "arrowtail", uid => "21", value => "dot"}
	       |       |--- attribute. Attributes: {name => "odot", port => "", type => "arrowhead", uid => "22", value => "odot"}
	       |       |--- literal. Attributes: {name => "]", port => "", type => "close_bracket", uid => "23", value => "]"}
	       |--- literal. Attributes: {name => "}", port => "", type => "close_brace", uid => "24", value => "}"}
	Parse result:  0 (0 is success)

You can see from this output that words special to Graphviz (e.g. STRICT) are accepted no matter
what case they are in. Such tokens are stored in lower-case.

A more detailed analysis follows.

The C<root> node has 2 daughters:

=over 4

=item o The C<prolog> sub-tree

The C<prolog> node is the root of a sub-tree holding everything before the graph's ID, if any.

The node is called C<prolog>, and its hashref of attributes is
C<< {type => "prolog_literal", uid => "1", value => "prolog"} >>.

It has 1 or 2 daughters. The possibilities are:

=over 4

=item o Input: 'digraph ...'

The 1 daughter is named C<literal>, and its attributes are
C<< {type => "digraph_literal", uid => "3", value => "digraph"} >>.

=item o Input: 'graph ...'

The 1 daughter is named C<literal>, and its attributes are
C<< {type => "graph_literal", uid => "3", value => "graph"} >>.

=item o Input: 'strict digraph ...'

The 2 daughters are named C<literal>, and their attributes are, respectively,
C<< {type => "strict_literal", uid => "3", value => "strict"} >> and
C<< {type => "digraph_literal", uid => "4", value => "digraph"} >>.

=item o Input: 'strict graph ...'

The 2 daughters are named C<literal>, and their attributes are, respectively,
C<< {type => "strict_literal", uid => "3", value => "strict"'} >> and
C<< {type => "graph_literal", uid => "4", value => "graph"} >>.

=back

And yes, the graph ID, if any, is under the C<graph> node. The reason for this is that for every
subgraph within the graph, the same structure applies: First the (sub)graph ID, then a literal
'{', then that (sub)graph's details, and finally a literal '}'.

=item o The 'graph' sub-tree

The C<graph> node is the root of a sub-tree holding everything about the graph, including the graph's
ID, if any.

The node is called C<graph>, and its hashref of attributes is
C<< {type => "graph_literal", uid => "2", value => "graph"} >>.

The C<graph> node has as many daughters, with their own daughters, as is necessary to hold the
output of parsing the remainder of the input.

In particular, if the input graph has an ID, i.e. the input is of the form 'digraph my_id ...'
(or various versions thereof) then the 1st daughter will be called C<node_id>, and its attributes
will be C<< {type => "node_id", uid => "5", value => "my_id"} >>.

Futher, the 2nd daughter will be called C<literal>, and its attributes will be
C<< {ype => "open_brace", uid => "6", value => "{"} >>. A subsequent daughter will eventually (for a
syntax-free input file, of course) also be called C<literal>, and its attributes will be
C<< {type => "close_brace", uid => "#", value => "}"} >>.

Naturally, if the graph has no ID (i.e. input lacks the 'my_id' token) then the uids will differ
slightly.

As mentioned, this pattern of optional (sub)graph id followed by a matching pair of '{', '}' nodes,
is used for all graphs and subgraphs.

In the case the input contains an explicit C<subgraph>, then just before the node representing
'my_id' or '{', there will be another node representing the C<subgraph> token.

It's name will be C<literal>, and its attributes will be
C<< {type => "subgraph_literal", uid => "#", value => "subgraph"} >>.

=back

=head2 How many different names can these nodes have?

The list of possible node names follows. You should always examine the C<type> and C<value> keys of
the node's attributes to determine the exact nature of the node.

=over 4

=item o attribute

In this case, the node's attributes contain a hashref like
{type => "arrowhead", uid => "33", value => "odiamond"}, meaning the C<type> field holds the type
(i.e. name) of the attribute, and the 'value' field holds the value of the attribute.

=item o class

This is used when any of C<edge>, C<graph>, or C<node> appear at the start of the (sub)graph, and
is the mother of the attributes attached to the class. The C<value> of the attribute will be
C<edge>, C<graph>, or C<node>.

The 1st and last daughters will be literals whose attribute values are '[' and ']' respectively,
and the middle daughter(s) will be nodes of type C<attribute> (as just discussed).

=item o edge_id

The C<value> of the attribute will be either '--' or '->'.

Thus the C<tail> of the edge will be the previous daughter (node or subgraph), and the C<head> of
the edge will be the next.

Samples are:

	n1 -> n2
	n1 -> {n2}
	{n1} -> n2

In a L<daisy chain|https://en.wikipedia.org/wiki/Garland#Daisy_chain> of nodes, the last node in
the chain may have daughters that are the attributes of each edge in the chain. This is how
Graphviz syntax attaches edge attributes to a path. The class C<edge> can also be used to provide
attributes for the edge.

=item o graph

There is only ever 1 node called C<graph>. This tree node is always present.

=item o graph_id

There is only ever 1 node called C<graph_id>.

If present, it's mother must be the tree node called C<graph>, in which case it will be the first
daughter of C<graph>.

But, it will be absent if the graph is unnamed, as in strict digraph /* no name */ {...}.

=item o literal

C<literal> is the name of some nodes, with the C<value> key in the attributes having one of these
values:

=over 4

=item o {

Indicates the start of a (sub)graph.

=item o }

Indicates the end of a (sub)graph.

=item o [

This indicates the start of a set of attributes for a specific class, edge or node, or the
edge attributes at the end of a path.

The 1st and last daughters will be literals whose attribute C<value> keys are '[' and ']'
respectively.

Between these 2 nodes will be 1 node for each attribute, as seen above with
C<< edge ["color" = "green",] >>.

Note: Graphviz allows an abbreviated syntax for setting the attributes of a (sub)graph. So, instead
of needing:

	graph [rankdir = LR]

You can just use:

	rankdir = LR

In such cases, these attributes are not surrounded by '[' and ']'.

=item o ]

See the previous point.

=item o digraph_literal

=item o graph_literal

=item o strict_literal

=item o subgraph_literal

=back

=item o node_id

The C<value> of the attributes is the name of the graph, a node, or a subgraph.

Note: A node name can appear more than once in succession, either as a declaration of the node's
existence and then as the tail of an edge, or, as in this fragment of data/56.gv:

	node [shape=rpromoter colorscheme=rdbu5 color=1 style=filled fontcolor=3]; Hef1a; TRE; UAS;
	Hef1aLacOid; Hef1aLacOid [label="Hef1a-LacOid"];

This is a case where tree compression could be done, but isn't done yet.

=item o prolog

There is only ever 1 node called C<prolog>. This tree node is always present.

=item o root

There is only ever 1 node called C<root>. This tree node is always present.

=back

=head2 How are nodes, ports and compass points represented in the (above) tree?

Input contains this fragment of data/17.02.gv:

	node_17_02_1:p11 -> node_17_02_2:p22:s
	[
		arrowhead = "odiamond";
		arrowtail = "odot",
		color     = red
		dir       = both;
	];

The output log contains:

	|   |--- node_id. Attributes: {node => "node_17_02_1", port => ":p11", type => "node_id", uid => "29", value => "node_17_02_1:p11"}
	|   |--- edge_id. Attributes: {name => "directed_edge", node => "->", port => "", uid => "30", value => "->"}
	|   |--- node_id. Attributes: {node => "node_17_02_2", port => ":p22:s", type => "node_id", uid => "31", value => "node_17_02_2:p22:s"}

You can see the ports and compass points have been incorporated into the C<value> attribute, and
that is value comes from concatenating the values of the C<node> and C<port> attributes.

See L</decode_port_compass($name)> and L</decode_node($node)>.

=head2 How are HTML-like labels handled

The main grammar (See C<< $self -> bnf >> in the source) is used to hold the definitions of strings
(See C<strict_literal>). Thus Marpa, via the main parser C<< $self -> recce >>, is used to identify
all types of strings.

Then, if the string starts with '>', C<_process_html()> is called, and has a separate grammar
(See C<bnf4html>). This in turn uses a separate grammar object (C<grammar4html>) and a separate
parser (C<recce4html>). C<_process_html()> traps any I<apparent> parsing errors, found when lexemes
(text) follows the HTML, and saves the label's value. This method also sets $pos to the first char
after the HTML, so when control returns to the main parser, and the main grammar, the main parser
is not aware of the existence of the HTML, and just keeps on parsing from where the HTML parser
finished.

=head2 How are comments stored in the tree?

They aren't stored, they are discarded. And this in turn means rendered C<dot> files can't ever
contain them.

=head2 What is the homepage of Marpa?

L<http://savage.net.au/Marpa.html>.

That page has a long list of links.

=head2 Why do I get error messages like the following?

	Error: <stdin>:1: syntax error near line 1
	context: digraph >>>  Graph <<<  {

Graphviz reserves some words as keywords, meaning they can't be used as an ID, e.g. for the
name of the graph.

So, don't do this:

	strict graph graph{...}
	strict graph Graph{...}
	strict graph strict{...}
	etc...

Likewise for non-strict graphs, and digraphs. You can however add double-quotes around such
reserved words:

	strict graph "graph"{...}

Even better, use a more meaningful name for your graph...

The keywords are: node, edge, graph, digraph, subgraph and strict. Compass points are not keywords.

See L<keywords|http://www.graphviz.org/content/dot-language> in the discussion of the syntax of DOT
for details.

=head2 Does this package support Unicode in the input C<dot> file?

Yes.

But you are I<strongly encouraged> to put node names using utf8 glyphs in double-quotes, even though
it is not always necessary.

See xt/author/data/utf8.*.gv and scripts/test.utf8.sh. In particular, see xt/author/data/utf8.01.gv.

=head2 How can I switch from Marpa::XS to Marpa::PP?

Don't use either of them. Use L<Marpa::R2>.

=head2 If I input x.old.gv and output x.new.gv, should these 2 files be identical?

Yes - at least in the sense that running C<dot> on them will produce the same output files.
This is assuming the default renderer is used.

See scripts/test.utf8.pl for how to do just that.

As mentioned just above, comments in input files are discarded, so they can never be in the output
file.

=head2 How are custom graph attributes handled?

They are treated like any other attribute. That is, syntax checking is not performed at that level,
but only at the grammatical level. If the construct matches the grammar, this code accepts it.

See data/32.gv.

=head2 How are the demo files generated?

See scripts/generate.demo.sh.

=head2 How do I run author tests?

This runs both standard and author tests:

	shell> perl Build.PL; ./Build; ./Build test; ./Build authortest

There are currently (V 2.00) 91 standard tests, and in xt/author/*.t, 4 pod tests and 355 author
tests. Combined, they take almost 2m 30s to run.

=head1 See Also

L<Marpa::Demo::StringParser>. The significance of this module is that during the re-write of
GraphViz2::Marpa V 1 => 2, the string-handling code was built-up step-by-step in
L<Marpa::Demo::StringParser>.

Later, that code was improved within this module, and will be back-ported into
Marpa::Demo::StringParser. In particular the technique used in _process_html() really should be
back-ported.

Also, see L<GraphViz2::Marpa::PathUtils> for 2 ways the tree built by this module can be processed
to provide analysis of the structure of the graph.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Thanks

Many thanks are due to the people who worked on L<Graphviz|http://www.graphviz.org/>.

Jeffrey Kegler wrote Marpa and L<Marpa::R2>.

And thanks to rns (Ruslan Shvedov) for writing the grammar for double-quoted strings used in
L<MarpaX::Demo::SampleScripts>'s scripts/quoted.strings.02.pl. I adapted it to HTML (see
scripts/quoted.strings.05.pl in that module), and then incorporated the grammar into this module.
For details, search for C<bnf4html>, C<grammar4html> and C<recce4html> in the source of the current
module.

=head1 Repository

L<https://github.com/ronsavage/GraphViz2-Marpa>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=GraphViz2::Marpa>.

=head1 Author

L<GraphViz2::Marpa> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Marpa's homepage: <http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
