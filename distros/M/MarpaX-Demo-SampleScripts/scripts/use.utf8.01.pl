#!/usr/bin/env perl

use 5.010;
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Marpa::R2;

use Try::Tiny;

# Author: Ron Savage.

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

# ------------------------------------------------

sub process
{
	my($recce, $string) = @_;
	my($length) = length $string;

	my(@event, $event_name);
	my($lexeme, $lexeme_name, $literal);
	my($start, $span);
	my($value);

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

		#print "\tpause_span($lexeme_name) => start: $start. span: $span. " .
		#	"lexeme: $lexeme. event: $event_name. \n";

		if ($event_name eq 'double_quoted_string')
		{
			$pos     = $recce -> lexeme_read($lexeme_name);
			$literal = substr($string, $start, $pos - $start);
			#$literal = '' if ($literal eq '""'); # Empty string is a special case.

			print "OK. event: $event_name. lexeme: <$literal> \n";
		}
		elsif ($event_name eq 'empty_string')
		{
			$pos     = $recce -> lexeme_read($lexeme_name);
			$literal = substr($string, $start, $pos - $start);
			#$literal = '' if ($literal eq '""'); # Empty string is a special case.

			print "OK. event: $event_name. lexeme: <$literal> \n";
		}
		elsif ($event_name eq 'single_quoted_string')
		{
			$pos     = $recce -> lexeme_read($lexeme_name);
			$literal = substr($string, $start, $pos - $start);
			#$literal = '' if ($literal eq '""'); # Empty string is a special case.

			print "OK. event: $event_name. lexeme: <$literal> \n";
		}
		else
		{
			die "Unexpected lexeme '$lexeme_name' with a pause\n";
		}
	}

	return $recce -> value;

} # End of process.

# ------------------------------------------------

my $bnf = <<'END_OF_GRAMMAR';

:default				::= action => [values]

lexeme default			=  latm => 1		# Longest Acceptable Token Match.

:start					::= string_token

string_token			::= unquoted_body
							| double_quoted_string
							| single_quoted_string
							| empty_string

# Lexemes in alphabetical order.

double_quoted_non_quote	~ [^"]

# Comment with " just for the UltraEdit syntax hiliter.

:lexeme					~ double_quoted_string		pause => before		event => double_quoted_string

double_quoted_string	~ ["] double_quoted_body ["]
double_quoted_string	~ ["] ["]

double_quoted_body		~ double_quoted_char_set+

double_quoted_char_set	~ escaped_double_char | escaped_double_quote | double_quoted_non_quote

:lexeme					~ empty_string				pause => before		event => empty_string

# For accepted and rejected by Marpa, see
# Marpa-R2-2.0xx000/lib/Marpa/R2/meta/metag.bnf.

#empty_string			~ '""'				# Accepted by Marpa.
#empty_string			~ ["] ['] ['] ["]	#		"
#empty_string			~ ''				# Rejected by Marpa.
#empty_string			~ ""				#		"
empty_string			~ ['] [']
empty_string			~ ["] ["]

escaped_double_char		~ '\' double_quoted_non_quote

# Comment with ' just for the UltraEdit syntax hiliter.

escaped_double_quote	~ '\"'

escaped_single_char		~ '\' single_quoted_non_quote

# Comment with ' just for the UltraEdit syntax hiliter.

escaped_single_quote	~ '\' [']

# Comment with ' just for the UltraEdit syntax hiliter.

single_quoted_non_quote	~ [^']

# Comment with ' just for the UltraEdit syntax hiliter.

:lexeme					~ single_quoted_string		pause => before		event => single_quoted_string

single_quoted_string	~ ['] single_quoted_body [']
single_quoted_string	~ ['] [']

single_quoted_body		~ single_quoted_char_set+

single_quoted_char_set	~ escaped_single_char | escaped_single_quote | single_quoted_non_quote

:lexeme					~ unquoted_body				pause => before		event => single_quoted_string

unquoted_body			~ unquoted_char_set+

unquoted_char_set		~ [\w\W] # Any character.

# Boilerplate.

:discard				~ whitespace
whitespace				~ [\s]+

END_OF_GRAMMAR

my($g)     = Marpa::R2::Scanless::G->new({source => \$bnf});
my(%count) = (in => 0, success => 0);

my($input);
my($parser);
my($result);
my($value);

for my $work
(
	['OK', q(Reichwaldstraße)],		# 1.
	['OK', q(Πηληϊάδεω Ἀχιλῆος)],	# 2.
	['OK', q(Δ Lady)],				# 3.
)
{
	$count{in}++;

	$result = $$work[0];
	$input  = $$work[1];

	print "In count: $count{in}:\nInput:  ->$input<- Expected result: $result. \n";

	$parser = Marpa::R2::Scanless::R->new
	({
		grammar         => $g,
		#trace_terminals => 99,
	});

	try
	{
		$value = process($parser, $input);

		if (! defined $value)
		{
			print "Parse failure!\n";
		}
		else
		{
			$count{success}++;

			print "Output: ->", decode_result($$value), "<- OK count: $count{success}. \n";
		}
	}
	catch
	{
		print "Exception: $_\n";
	};

	print "\n";
}

print 'Counts: ', join('. ', map{"$_ => $count{$_}"} sort keys %count), ". \n";
