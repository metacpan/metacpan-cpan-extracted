#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Marpa::R2;

use Try::Tiny;

# Author: Christopher Layne.
# See https://groups.google.com/forum/#!topic/marpa-parser/kthX_WUfE_o.

# ------------------------------------------------

# Deescaping table.

my($xtab) =
{
	'eqd'  => { q(\") => qq(") },
	'eqs'  => { q(\') => qq(') },
	'eql0' => { q(\|) => qq(|) },
	'eql1' => { q(\%) => qq(%) },

#	Not presently used.

#	'eqx'  =>
#	{
#		q(\a)   => qq(\a),
#		q(\b)   => qq(\b),
#		q(\e)   => qq(\e),
#		q(\f)   => qq(\f),
#		q(\n)   => qq(\n),
#		q(\r)   => qq(\r),
#		q(\t)   => qq(\t),
#		q(\")   => qq("),
#		q(\')   => qq('),
#		q(\\\\) => qq(\\),
#	},
};

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
# Deescaping functions.

sub val_eqd  { return [ join '', map +($$xtab{'eqd'}{$_}  || $_), @{$_[1]} ] }
sub val_eqs  { return [ join '', map +($$xtab{'eqs'}{$_}  || $_), @{$_[1]} ] }
sub val_eql0 { return [ join '', map +($$xtab{'eql0'}{$_} || $_), @{$_[1]} ] }
sub val_eql1 { return [ join '', map +($$xtab{'eql1'}{$_} || $_), @{$_[1]} ] }
#sub val_eqx { return [ join '', map +($$xtab{'eqx'}{$_}  || $_), @{$_[1]} ] }

# ------------------------------------------------
# Dequoting functions.

sub val_qd  { return [ substr($_[1]->[0], 1, -1) ] }
sub val_qs  { return [ substr($_[1]->[0], 1, -1) ] }
sub val_ql0 { return [ substr($_[1]->[0], 2, -1) ] }
sub val_ql1 { return [ substr($_[1]->[0], 2, -1) ] }

# ------------------------------------------------

my($bnf) =
q{
	:default			::= action => [values]

	lexeme default		= latm => 1

	# Normal, bare, unquoted.

	value				::= value_n
	value_n				::= valword_n

	# Quoted but not escaped.

	value				::= value_qd									action => val_qd
							| value_qs									action => val_qs
							| value_ql0									action => val_ql0
							| value_ql1									action => val_ql1
	value_qd			::= valword_qd
	value_qs			::= valword_qs
	value_ql0			::= valword_ql0
	value_ql1			::= valword_ql1

	# Quoted and escaped.

	value           	::= (g_quote_d) value_eqd (g_quote_d)			action => val_eqd
							| (g_quote_s) value_eqs (g_quote_s)			action => val_eqs
							| (g_quote_ls0) value_eql0 (g_quote_le0)	action => val_eql0
							| (g_quote_ls1) value_eql1 (g_quote_le1)	action => val_eql1
	value_eqd			::= valword_eqd*
	value_eqs			::= valword_eqs*
	value_eql0			::= valword_eql0*
	value_eql1			::= valword_eql1*

	# Lexemes.
	# Normal, bare, unquoted.

	valword_n			~ valword_n_c
	valword_n_c			~ [\w_\@:.\/\*-]+

	# Quoted but not escaped.

	valword_qd			~ quote_d valword_qd_c quote_d
	valword_qs			~ quote_s valword_qs_c quote_s
	valword_ql0			~ quote_ls0 valword_ql0_c quote_le0
	valword_ql1			~ quote_ls1 valword_ql1_c quote_le1
	valword_qd_c		~ [^"\\\]*
	valword_qs_c		~ [^'\\\]*
	valword_ql0_c		~ [^|\\\]*
	valword_ql1_c		~ [^%\\\]*

	# Quoted and escaped.

	valword_eqd			~ valword_eqd_c
	valword_eqs			~ valword_eqs_c
	valword_eql0		~ valword_eql0_c
	valword_eql1		~ valword_eql1_c
	valword_eqd_c		~ [^"] | whitespace | escape ["]
	valword_eqs_c		~ [^'] | whitespace | escape [']
	valword_eql0_c		~ [^|] | whitespace | escape [|]
	valword_eql1_c		~ [^%] | whitespace | escape [%]

	# These do translation, but cannot be enabled yet as the expectation is no translation.
	# valword_eqd     ~ [^\a\b\e\f\r\n\t\\"] | whitespace | escape valword_esc
	# valword_eqs     ~ [^\a\b\e\f\r\n\t\\'] | whitespace | escape valword_esc
	# valword_esc     ~ [abefrnt\\"']

	# The same base lexemes cannot be directly used by both the lexer and grammar *at the same time*.
	# Work around it by providing wrapper lexeme rules for the grammar which end up at the same terminal.

	g_quote_d         ~ quote_d
	g_quote_s         ~ quote_s
	g_quote_ls0       ~ quote_ls0
	g_quote_le0       ~ quote_le0
	g_quote_ls1       ~ quote_ls1
	g_quote_le1       ~ quote_le1

	quote_d           ~ ["]
	quote_s           ~ [']
	quote_ls0         ~ 'q|'
	quote_le0         ~ '|'
	quote_ls1         ~ 'q%'
	quote_le1         ~ '%'
	escape            ~ '\'

	:discard          ~ whitespace
	whitespace        ~ [\s]+
};

my(%count) = (in => 0, success => 0);
my($g)     = Marpa::R2::Scanless::G -> new({source => \$bnf});

my($input);
my($parser);
my($result);
my($value);

for my $work
(
	['OK', 'one'],
	['OK', "two"],
	['OK', q|three|],
	['OK', q%four%],
	['OK', 'fi\"ve'],
	['OK', "si\"x"],
	['OK', 'sev en'],
)
{
	$count{in}++;

	$result = $$work[0];
	$input  = $$work[1];

	print "In count: $count{in}:\nInput:  ->$input<- Expected result: $result\n";

	$parser = Marpa::R2::Scanless::R->new
	({
		grammar           => $g,
		semantics_package => 'main',
		#trace_terminals  => 99,
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
