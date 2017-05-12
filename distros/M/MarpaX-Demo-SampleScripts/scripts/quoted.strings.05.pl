#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Marpa::R2;

use Try::Tiny;

# Author: rns (Ruslan Shvedov).
# See https://groups.google.com/forum/#!topic/marpa-parser/kthX_WUfE_o.
# Adapted from balanced parens example in
# http://marvin.cs.uidaho.edu/Teaching/CS445/grammar.html
# See quoted.strings.02.pl.
# Adapted by Ron Savage for HTML.

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

my($bnf) =
q{
	:default		::= action => [ values ]

	lexeme default	= latm => 1

	string			::= '<' quoted '>'
	quoted			::= item | quoted item
	item			::= string | unquoted

	unquoted		~ [^<>]+ # <>.

	:discard		~ whitespace
	whitespace		~ [\s+]
};

my(%count) = (in => 0, success => 0);
my($g)     = Marpa::R2::Scanless::G -> new({source => \$bnf});

my($input);
my($parser);
my($result);
my($value);

for my $work
(
	['OK', q|<.    .>|],
	['OK', q|<<table><tr><td>HTML table</td></tr></table>>|],
	['OK', q|<<table><tr><td>'HTML table'</td></tr></table>>|],
	['OK', q|<<table><tr><td>html-style label</td></tr></table>>|],
	['OK', q|<<table><tr><td>HTML table: 'X' &amp; "Y" &amp; "Z"</td></tr></table>>|],
	['OK', q|<<table><tr><td>html-style label with literal &lt;&gt;</td></tr></table>>|],
	['OK', q|<<table><tr><td>html-style label with &lt;&gt; embedded angle brackets</td></tr></table>>|],
	['OK', q|<<table border='0'><tr><td>html-style label with literal &lt;br /&gt; and no table border</td></tr></table>>|],
	['OK', q|<<table border='0'><tr><td>html-style label with 2 <br align='center' /> &lt;br /&gt;s in the middle <br align='center' /> and without a table border.</td></tr></table>>|],
	['OK', q|<<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0">
	<TR><TD>"ZapfChancery-MediumItalic"</TD></TR>
	<TR><TD>"ABCDEFGHIJLKLMNOPQRSTUVWXYZ"</TD></TR>
	<TR><TD>"abcdefghijlklmnopqrstuvwxyz"</TD></TR>
	<TR><TD>"ABCDEFGHIJLKLMNOPQRSTUVWXYZ\nabcdefghijlklmnopqrstuvwxyz"</TD></TR>
	</TABLE>>|],
)
{
	$count{in}++;

	$result = $$work[0];
	$input  = $$work[1];

	print "In count: $count{in}:\nInput:  ->$input<- Expected result: $result\n";

	$parser = Marpa::R2::Scanless::R->new
	({
		grammar          => $g,
		ranking_method   => 'high_rule_only',
		#trace_terminals => 99,
	});

	try
	{
		$parser -> read(\$input);

		print "Ambiguous parse!\n" if ($parser -> ambiguity_metric() > 1);

		$value = $parser -> value;

		if (! defined $value)
		{
			print "Parse failure!\n";
		}
		else
		{
			$count{success}++;

			print "Output: ->", decode_result($$value), "<- Success count: $count{success}. \n";
		}
	}
	catch
	{
		print "Exception: $_";
	};

	say "\n";
}

print 'Counts: ', join('. ', map{"$_ => $count{$_}"} sort keys %count), ". \n";
