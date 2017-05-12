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

	S				::= '"' quoted '"'
	quoted			::= item | quoted item
	item			::= S | unquoted

	unquoted		~ [^"]+		# Add " for syntax highlight correction.

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
	['OK', '"these are "words in typewriter double quotes" and then some"'],
	['OK', '"these are "words in "nested typewriter double" quotes" and then some"'],
	['OK', '"these are "words in "nested "and even more nested" typewriter double" quotes" and then some"'],
	['OK', '""'],
)
{
	$count{in}++;

	$result = $$work[0];
	$input  = $$work[1];

	print "In count: $count{in}:\nInput:  ->$input<- Expected result: $result\n";

	$parser = Marpa::R2::Scanless::R->new
	({
		grammar         => $g,
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
