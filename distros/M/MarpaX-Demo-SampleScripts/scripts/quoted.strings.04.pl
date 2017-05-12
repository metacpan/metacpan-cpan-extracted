#!/usr/bin/env perl

use 5.010;
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Marpa::R2;

use Moo;

use Try::Tiny;

use Types::Standard qw/ArrayRef Str/;

has recce =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our @fields;

# Author: Ron Savage.

# --------------------------------------------------

sub clean_after
{
	my($self, $s) = @_;

	$s =~ s/^\s+//;
	$s =~ s/\s+$//;
	$s =~ s/^([\"\'])(.+)\1$/$2/; # The backslashes are just for the UltraEdit syntax hiliter.
	$s =~ s/^\s+//;
	$s =~ s/\s+$//;

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

# ------------------------------------------------

sub decode_result
{
	my($result)   = @_;
	my(@worklist) = $result;

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

} # End of decode_result.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	print "$s\n";

} # End of log.

# ------------------------------------------------

sub process
{
	my($self, $recce, $input) = @_;
	my($string) = clean_before(undef, $input);
	my($length) = length $string;

	# We use read()/lexeme_read()/resume() because we pause at each lexeme.

	my(@event, $event_name);
	my($lexeme_name, $lexeme, $literal);
	my($span, $start);

	for
	(
		my $pos = $recce -> read(\$string);
		$pos < $length;
		$pos = $recce -> resume($pos)
	)
	{
		@event          = @{$recce -> events};
		$event_name     = ${$event[0]}[0];
		($start, $span) = $recce -> pause_span;
		$lexeme_name    = $recce -> pause_lexeme;
		$lexeme         = $recce -> literal($start, $span);

		main::log(undef, debug => "pause_span($lexeme_name) => start: $start. span: $span. " .
			"lexeme: $lexeme. event: $event_name");

		if ($event_name eq 'end_attributes')
		{
			$pos     = $recce -> lexeme_read($lexeme_name);
			$literal = substr($string, $start, $pos - $start);

			main::log(undef, debug => "End attributes: !$literal!");
		}
		elsif ($event_name =~ /(?:double_quoted_string|empty_string|single_quoted_string|unquoted_string)/)
		{
			$pos     = $recce -> lexeme_read($lexeme_name);
			$literal = substr($string, $start, $pos - $start);
			$pos     = skip_separator(undef, $string, $pos);

			push @fields, $literal;

			# Allow for custom attribute names starting with '/label[a-z]i/'.
			# If it's not one of those, then it's a real label.
			# But is the value HTML? If so, activate special processing.

			if (substr($string, $pos, 6) =~ /label[^a-z]/i)
			{
				# Look for a separator after 'label' and then a '<'.
				# If both are found, it's a HTML label.

				my($offset) = skip_separator(undef, $string, $pos + 6, 1);
				my($char)   = substr($string, $offset, 1);

				if ($char eq '<')
				{
					push @fields, 'label';

					$pos = _process_html(undef, \@fields, $string, $offset);
				}
			}
		}
		elsif ($event_name =~ /(?:(?:|un)directed_edge)/)
		{
			$pos     = $recce -> lexeme_read($lexeme_name);
			$literal = substr($string, $start, $pos - $start);

			push @fields, $literal;

			main::log(undef, debug => "Edge: $literal");
		}
		elsif ($event_name eq 'start_attributes')
		{
			$pos     = $recce -> lexeme_read($lexeme_name);
			$literal = substr($string, $start, $pos - $start);

			main::log(undef, debug => "Start attributes: !$literal!");
		}
		elsif ($event_name eq 'start_node')
		{
			$pos     = $recce -> lexeme_read($lexeme_name);
			$literal = substr($string, $start, $pos - $start);

			main::log(undef, debug => "Start node: !$literal!");
		}
		else
		{
			die "Unexpected lexeme '$lexeme_name' with a pause\n";
		}
    }

	@fields = map{clean_after(undef, $_)} @fields;

	# Return a defined value for success and undef for failure.
	# The length test means we return success for empty input.

	return ($length > 0) ? $recce -> value : '';

} # End of process.

# ------------------------------------------------

sub _process_html
{
	my($self, $fields, $string, $pos) = @_;
	my($angle_bracket_count) = 0;
	my($length)              = length($string);
	my($finished)            = $pos >= $length;

	# Basically, we assume the HTML is valid, and copy chars while watching '<' and '>' characters.
	# If one of those chars is escaped, it's a normal char of course. Otherwise we push and pop them,
	# so when we encounter the '>' which matches the first '<', we're done.

	my(@html);

	main::log(undef, debug => 'String: !' . substr($string, $pos) . "!. pos: $pos. Remaining length: $length");

	while (! $finished)
	{
		push @html, substr($string, $pos, 1);

		if ($html[$#html] eq '<')
		{
			$angle_bracket_count++;
		}
		elsif ($html[$#html] eq '>')
		{
			$angle_bracket_count--;
		}

		$pos++;

		$finished = ($angle_bracket_count == 0) || ($pos >= $length);
	}

	$pos = skip_separator(undef, $string, $pos);

	$html[0] = join('', @html);

	main::log(undef, debug => "Stack: !$html[0]!");

	push @$fields, $html[0];

	return $pos;

} # End of _process_html.

# ------------------------------------------------

sub skip_separator
{
	my($self, $string, $pos) = @_;

	# Look for a separator, [;:].

	my($char) = substr($string, $pos, 1);

	while ( (length($char) > 0) && ($char =~ /[\s;:]/) )
	{
		$pos++;

		$char = substr($string, $pos, 1);
	}

	return $pos;

} # End of skip_separator.

# ------------------------------------------------

my $bnf = <<'END_OF_GRAMMAR';

:default				::= action => [values]

lexeme default			=  latm => 1		# Longest Acceptable Token Match.

graph_grammar			::= graph_definition

# Graph stuff.

graph_definition		::= node_definition
							| edge_definition
# Node stuff

node_definition			::= node_statement
							| node_statement graph_definition

node_statement			::= node_name
							| node_name attribute_definition
							| node_statement (',') node_statement

node_name				::= start_node string_token end_node

# Edge stuff

edge_definition			::= edge_statement
							| edge_statement graph_definition

edge_statement			::= edge_name
							| edge_name attribute_definition
							| edge_statement (',') edge_statement

edge_name				::= directed_edge
							| undirected_edge

# Attribute stuff.

attribute_definition	::= attribute_statement*

attribute_statement		::= start_attributes string_token_set end_attributes

string_token_set		::= string_token+

string_token			::= unquoted_string
							| double_quoted_string
							| single_quoted_string
							| empty_string

# Lexemes in alphabetical order.

:lexeme					~ directed_edge				pause => before		event => directed_edge
directed_edge			~ '->'

double_quoted_non_quote	~ [^"]

# Comment with " just for the UltraEdit syntax hiliter.

:lexeme					~ double_quoted_string		pause => before		event => double_quoted_string

double_quoted_string	~ ["] double_quoted_body ["]
double_quoted_string	~ ["] ["]

double_quoted_body		~ double_quoted_char_set+

double_quoted_char_set	~ escaped_colon
							| escaped_semi_colon
							| escaped_double_char
							| escaped_double_quote
							| double_quoted_non_quote

:lexeme					~ empty_string				pause => before		event => empty_string

#empty_string			~ '""'				# Accepted by Marpa.
#empty_string			~ ["] ['] ['] ["]	#		"
#empty_string			~ ''				# Rejected by Marpa.
#empty_string			~ ""				#		"
empty_string			~ ['] [']
empty_string			~ ["] ["]

:lexeme					~ end_attributes			pause => before		event => end_attributes		priority => 1
end_attributes			~ '}'

:lexeme					~ end_node					priority => 1
end_node				~ ']'

escaped_colon			~ '\:'

escaped_double_char		~ '\' double_quoted_non_quote

# Comment with ' just for the UltraEdit syntax hiliter.

escaped_double_quote	~ '\"'

escaped_single_char		~ '\' single_quoted_non_quote

# Comment with ' just for the UltraEdit syntax hiliter.

escaped_semi_colon		~ '\;'

#escaped_single_quote	~ '\''				# Rejected by Marpa.
escaped_single_quote	~ '\' [']

# Comment with ' just for the UltraEdit syntax hiliter.

single_quoted_non_quote	~ [^']

# Comment with ' just for the UltraEdit syntax hiliter.

:lexeme					~ single_quoted_string		pause => before		event => single_quoted_string

single_quoted_string	~ ['] single_quoted_body [']
single_quoted_string	~ ['] [']

single_quoted_body		~ single_quoted_char_set+

single_quoted_char_set	~ escaped_colon
							| escaped_semi_colon
							| escaped_single_char
							| escaped_single_quote
							| single_quoted_non_quote

:lexeme					~ start_attributes			pause => before		event => start_attributes
start_attributes		~ '{'

:lexeme					~ start_node				pause => before		event => start_node
start_node				~ '['

:lexeme					~ undirected_edge			pause => before		event => undirected_edge
undirected_edge			~ '--'

unquoted_char_set		~ escaped_colon
							| escaped_semi_colon
							| [^;:}\]] # Neither a separator [;:] nor a terminator [}\]].

:lexeme					~ unquoted_string			pause => before		event => unquoted_string

unquoted_string			~ unquoted_char_set+

# Boilerplate.

:discard				~ whitespace
whitespace				~ [\s]+

END_OF_GRAMMAR

# A " to fix UltraEdit's syntax parser.

my($g)     = Marpa::R2::Scanless::G->new({source => \$bnf});
my(%count) = (in => 0, success => 0);

my($input);
my($parser);
my($recce, $result);
my($value);

for my $work
(
	['OK', q(-> {color:cornflowerblue; label: This edge's color is blueish ;})],	# 1
	#['OK', q([])],			# 2.
	#['OK', q([Perl 6])],	# 3.
)
{
	$count{in}++;

	$result = $$work[0];
	$input  = $$work[1];

	print "In count: $count{in}:\nInput:  !$input! Expected result: $result. \n";

	$recce = Marpa::R2::Scanless::R -> new
	({
		grammar         => $g,
		#trace_terminals => 99,
	});

	# Return 0 for success and 1 for failure.

	$result = 0;

	try
	{
		$value = process(undef, $recce, $input);

		if (defined $value)
		{
			$count{success}++;

			@fields = ('') if ($#fields < 0); # For empty input.

			for my $i (0 ... $#fields)
			{
				print "@{[$i + 1]}: !$fields[$i]!\n";
			}
		}
		else
		{
			$result = 1;

			print "Parse failed\n";
		}
	}
	catch
	{
		$result = 1;

		print "Parse failed. Error: $_\n";
	};

	print "\n";
}

print 'Counts: ', join('. ', map{"$_ => $count{$_}"} sort keys %count), ". \n";
