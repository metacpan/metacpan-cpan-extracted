package MarpaX::Grammar::GraphViz2;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use File::Basename; # For basename().
use File::Which; # For which().

use GraphViz2;

use List::AllUtils qw/first_index indexes/;

use Log::Handler;

use Types::Standard qw/Any Bool HashRef Int Str/;

use MarpaX::Grammar::Parser;

use Moo;

has bnf_name =>
(
	default  => sub{return 'BNF'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has default_count =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has discard_count =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has driver =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has event_count =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has format =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has g1_rules_seen =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has graph =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any, # Actually an Object.
	required => 0,
);

has legend =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has lexeme_count =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has logger =>
(
	default  => sub{return undef},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has marpa_bnf_file =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 1,
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

has nodes_seen =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa     => HashRef,
	required => 0,
);

has output_file =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has parser =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any, # Actually an Object.
	required => 0,
);

has root_name =>
(
	default  => sub{return 'DSL'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has user_bnf_file =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 1,
);

has verbose =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Bool,
	required => 1,
);

our $VERSION = '2.00';

# ------------------------------------------------

sub BUILD
{
	my($self)  = @_;

	die "No Marpa BNF file found\n" if (! -e $self -> marpa_bnf_file);
	die "No user BNF file found\n"  if (! -e $self -> user_bnf_file);

	$self -> driver($self -> driver || which('dot') );
	$self -> format($self -> format || 'svg');

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

	my($graph) ||= GraphViz2 -> new
		(
			edge   => {color => 'grey'},
			global => {directed => 1, driver => $self -> driver, format => $self -> format},
			graph  => {label => basename($self -> user_bnf_file), rankdir => 'TB'},
			logger => $self -> logger,
			node   => {shape => 'rectangle', style => 'filled'},
		);

	$self -> graph($graph);
	$self -> parser
	(
		MarpaX::Grammar::Parser -> new
		(
			marpa_bnf_file => $self -> marpa_bnf_file,
			logger         => $self -> logger,
			user_bnf_file  => $self -> user_bnf_file,
		)
	);

} # End of BUILD.

# ------------------------------------------------

sub add_legend
{
	my($self) = @_;

	$self -> graph -> push_subgraph
	(
		# No options...
		# Legend: top. Border: no. Label: no.
		#
		# label => 'cluster_legend',
		# Legend: top. Border: no. Label: no.
		#
		# name  => 'cluster_legend',
		# Legend: top. Border: yes. Label: *.bnf.
		#
		#graph => {label => 'cluster_legend'},
		# Legend: top. Border: no. Label: no. Not using subgraph => {...}.
		#graph => {label => 'cluster_Legend'},
		# Legend: bottom. Border: no. Label: no. Using subgraph => {...}.
		# Legend: top. Border: no. Label: no. Not using subgraph => {...}.
		subgraph => {rank => 'max'},
		# Legend: top. Border: no. Label: no. Using graph => {...}.
		# Legend: bottom. Border: no. Label: no. Not using graph => {...}.
	);

	$self -> graph -> add_node
	(
		label =>
q|
<<table bgcolor = 'white'>
<tr>
	<td bgcolor = 'pink'>Pink nodes are ':default' rules</td>
</tr>
<tr>
	<td bgcolor = 'magenta'>Magenta nodes are ':discard' rules</td>
</tr>
<tr>
	<td bgcolor = 'orchid'>The orchid node is the 'discard default' rule</td>
</tr>
<tr>
	<td bgcolor = 'goldenrod'>The golden node is the 'lexeme default' rule</td>
</tr>
<tr>
	<td bgcolor = 'lightblue'>The LightBlue node is the ':start' rule</td>
</tr>
<tr>
	<td bgcolor = 'CornflowerBlue'>CornflowerBlue nodes are G1 rules</td>
</tr>
<tr>
	<td bgcolor = 'lightgreen'>LightGreen nodes are ':lexeme' rules</td>
</tr>
</table>>
|,
		name  => 'Legend',
		shape => 'plaintext',
	);

	$self -> graph -> pop_subgraph;

} # End of add_legend.

# ------------------------------------------------

sub add_node
{
	my($self, %attributes) = @_;
	my($name) = delete $attributes{name};
 	my($seen) = $self -> nodes_seen;

	$self -> graph -> add_node(name => $name, %attributes) if (! $$seen{$name});

	$$seen{$name} = 1;

	$self -> nodes_seen($seen);

} # End of add_node.

# ------------------------------------------------

sub hashref2string
{
	my($self, $hashref) = @_;
	$hashref ||= {};

	return '{' . join(', ', map{qq|$_ => "$$hashref{$_}"|} sort keys %$hashref) . '}';

} # End of hashref2string.

# ------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> log($level => $s) if ($self -> logger);

} # End of log.

# ------------------------------------------------

sub _process_adverbs
{
	my($self, $daughters) = @_;

	my($attr);
	my(@adverbs);
	my(@grand_kids);
	my($name);
	my($token_1, $token_2);

	for my $j (2 .. $#$daughters)
	{
		$name       = $$daughters[$j] -> name;
		$attr       = $$daughters[$j] -> attributes;
		$token_1    = $$attr{token};
		@grand_kids = $$daughters[$j] -> daughters;

		last if ($#grand_kids < 0); # TODO. Alternative.

		$attr    = ($$daughters[$j] -> daughters)[0] -> attributes;
		$token_2 = $$attr{token};

		push @adverbs, "$token_1 =\\> $token_2";
	}

	if ($#adverbs >= 0)
	{
		$adverbs[0]         = "\{$adverbs[0]";
		$adverbs[$#adverbs] .= '}';
		@adverbs            = map{ {text => $_} } @adverbs;
	}

	return [@adverbs];

} # End of _process_adverbs.

# ------------------------------------------------

sub _process_bare_lexeme
{
	my($self, $daughters) = @_;

} # End of _process_bare_lexeme.

# ------------------------------------------------

sub _process_bare_rule
{
	my($self, $daughters) = @_;
	my($attr)       = ($$daughters[0] -> daughters)[0] -> attributes;
	my($token_1)    = $$attr{token};
	my($attributes) =
	{
		fillcolor => 'LightSkyBlue',
		label     => $token_1,
	};

	$self -> add_node(name => $token_1, %$attributes);

	# Loop over the alternative branches within this rule.
	# Note: There might by N rule tokens before 'alternative'.

	my($rules_seen) = $self -> g1_rules_seen;

	my(@hidden_tokens, @hidden_kids);
	my(@kids);
	my(@label);
	my($name);
	my($rule_name);
	my($token_2, $token_3);

	for (my $index = 2; $index <= $#$daughters; $index++)
	{
		$name = $$daughters[$index] -> name;

		if ($name eq 'alternative')
		{
			$rule_name          = join(' ', map{s/:/\x{a789}/; $_} @label);
			$$attributes{label} = $rule_name;

			$self -> add_node(name => $rule_name, %$attributes);
			$self -> graph -> add_edge(from => $token_1, to => $rule_name);

			for (@label)
			{
				next if ($_ eq $rule_name);

				$$attributes{label} = $_;

				$self -> add_node(name => $_, %$attributes);
				$self -> graph -> add_edge(from => $rule_name, to => $_);
			}

			@label = ();

			next;
		}
		elsif ($name eq 'parenthesized_rhs_primary_list')
		{
			@hidden_kids   = $$daughters[$index] -> daughters;
			@hidden_tokens = ('(');

			for (my $i = 0; $i <= $#hidden_kids; $i++)
			{
				$attr = $hidden_kids[$i] -> attributes;

				push @hidden_tokens, $$attr{token};
			}

			push @hidden_tokens, ')';
			push @label, join(' ', @hidden_tokens);

			$index++;

			next;
		}
		elsif ($name ne 'rhs')
		{
			next;
		}

		$attr = $$daughters[$index] -> attributes;
		@kids = $$daughters[$index] -> daughters;

		next if ($#kids < 0);

		$attr    = $kids[0] -> attributes;
		$token_2 = $$attr{token};

		push @label, $token_2;
	}

	if ($#label >= 0)
	{
		$rule_name          = join(' ', map{s/:/\x{a789}/g; $_} @label);
		$$attributes{label} = $rule_name;

		$self -> add_node(name => $rule_name, %$attributes);
		$self -> graph -> add_edge(from => $token_1, to => $rule_name);

		for (@label)
		{
			next if ($_ eq $rule_name);

			$$attributes{label} = $_;

			$self -> add_node(name => $_, %$attributes);
			$self -> graph -> add_edge(from => $rule_name, to => $_);
		}
	}

	$self -> g1_rules_seen($rules_seen);

} # End of _process_bare_rule.

# ------------------------------------------------

sub _process_default_rule
{
	my($self, $daughters) = @_;

	$self -> default_count($self -> default_count + 1);

	my($default_count) = $self -> default_count;
	my($default_name)  = "\x{a789}default";
	my($attributes)    =
	{
		fillcolor => 'pink',
		label     => [{text => " $default_name"}], # Warning: Don't delete the ' ' before the \x.
	};

	if ($default_count == 1)
	{
		$self -> add_node(name => $default_name, %$attributes);
		$self -> graph -> add_edge(from => $self -> root_name, to => $default_name);
	}

	my($adverbs) = $self -> _process_adverbs($daughters);

	if ($#$adverbs >= 0)
	{
		$$attributes{fillcolor} = 'pink';
		$$attributes{label}     = $adverbs;
		my($adverb_name)        = "${default_name}_$default_count";

		$self -> add_node(name => $adverb_name, %$attributes);
		$self -> graph -> add_edge(from => $default_name, to => $adverb_name);
	}

} # End of _process_default_rule.

# ------------------------------------------------

sub _process_discard_default_rule
{
	my($self, $daughters) = @_;
	my($discard_name) = "discard default";
	my($attributes)   =
	{
		fillcolor => 'orchid',
		label     => $discard_name,
	};

	$self -> add_node(name => $discard_name, %$attributes);
	$self -> graph -> add_edge(from => $self -> root_name, to => $discard_name);

	my($adverbs) = $self -> _process_adverbs($daughters);

	if ($#$adverbs >= 0)
	{
		$$attributes{fillcolor} = 'orchid';
		$$attributes{label}     = $adverbs;
		my($adverb_name)        = "${discard_name}_1";

		$self -> add_node(name => $adverb_name, %$attributes);
		$self -> graph -> add_edge(from => $discard_name, to => $adverb_name);
	}


} # End of _process_discard_default_rule.

# ------------------------------------------------

sub _process_discard_rule
{
	my($self, $daughters) = @_;

	$self -> discard_count($self -> discard_count + 1);

	my($discard_count) = $self -> discard_count;
	my($discard_name)  = "\x{a789}discard";
	my($attributes)    =
	{
		fillcolor => 'magenta',
		label     => [{text => " $discard_name"}], # Warning: Don't delete the ' ' before the \x.
	};

	if ($discard_count == 1)
	{
		$self -> add_node(name => $discard_name, %$attributes);
		$self -> graph -> add_edge(from => $self -> root_name, to => $discard_name);
	}

	my($attr)  = ($$daughters[2] -> daughters)[0] -> attributes;
	my($token) = $$attr{token};

	$$attributes{fillcolor} = 'magenta';
	$$attributes{label}     = $token;

	$self -> add_node(name => $token, %$attributes);
	$self -> graph -> add_edge(from => $discard_name, to => $token);

} # End of _process_discard_rule.

# ------------------------------------------------

sub _process_lexeme_adverbs
{
	my($self, $daughters) = @_;

	my($attr);
	my(@adverbs);
	my(@grand_kids);
	my($name);
	my($token_1, $token_2);

	for my $j (2 .. $#$daughters)
	{
		$name       = $$daughters[$j] -> name;
		$attr       = $$daughters[$j] -> attributes;
		$token_1    = $$attr{token};
		$attr       = ($$daughters[$j] -> daughters)[0] -> attributes;
		$token_2    = $$attr{token};

		push @adverbs, [$token_1, $token_2];
	}

	return [@adverbs];

} # End of _process_lexeme_adverbs.

# ------------------------------------------------

sub _process_lexeme_default_rule
{
	my($self, $daughters) = @_;
	my($lexeme_name) = 'lexeme default';
	my($attributes)  =
	{
		fillcolor => 'goldenrod',
		label     => $lexeme_name,
	};

	$self -> add_node(name => $lexeme_name, %$attributes);
	$self -> graph -> add_edge(from => $self -> root_name, to => $lexeme_name);

	my($adverbs) = $self -> _process_adverbs($daughters);

	if ($#$adverbs >= 0)
	{
		$$attributes{fillcolor} = 'goldenrod';
		$$attributes{label}     = $adverbs;
		my($adverb_name)        = "${lexeme_name}_1";

		$self -> add_node(name => $adverb_name, %$attributes);
		$self -> graph -> add_edge(from => $lexeme_name, to => $adverb_name);
	}

} # End of _process_lexeme_default_rule.

# ------------------------------------------------

sub _process_lexeme_rule
{
	my($self, $daughters) = @_;

	$self -> lexeme_count($self -> lexeme_count + 1);

	my($adverbs)      = $self -> _process_lexeme_adverbs($daughters);
	my($lexeme_count) = $self -> lexeme_count;
	my($lexeme_name)  = shift @$adverbs;
	$lexeme_name      = $$lexeme_name[1]; # Discard 'bare_name'.
	my($attributes)   =
	{
		fillcolor => 'DeepSkyBlue2',
		label     => [{text => " $lexeme_name"}], # Warning: Don't delete the ' ' before the \x.
	};

	if ($#$adverbs >= 0)
	{
		@$adverbs = map{"$$_[0] =\\> $$_[1]"} @$adverbs;

		unshift @$adverbs, " \x{a789}lexeme =\\> $lexeme_name";

		$$adverbs[0]          = "\{$$adverbs[0]";
		$$adverbs[$#$adverbs] .= '}';
		@$adverbs             = map{ {text => $_} } @$adverbs;
		$$attributes{label}   = $adverbs;
		my($adverb_name)      = "${lexeme_name}_$lexeme_count";

		$self -> add_node(name => $adverb_name, %$attributes);
		$self -> graph -> add_edge(from => $lexeme_name, to => $adverb_name);
	}

} # End of _process_lexeme_rule.

# ------------------------------------------------

sub _process_start_rule
{
	my($self, $daughters) = @_;
	my($name)       = 'start';
	my($attributes) =
	{
		fillcolor => 'Turquoise1',
		label     => [{text => " \x{a789}start"}], # Warning: Don't delete the ' ' before the \x.
	};

	$self -> add_node(name => $name, %$attributes);
	$self -> graph -> add_edge(from => $self -> root_name, to => $name);

	my($attr)           = ($$daughters[2] -> daughters)[0] -> attributes;
	my($starter)        = $$attr{token};
	$$attributes{label} = [{text => $$attr{token} }];

	$self -> add_node(name => $starter, %$attributes);
	$self -> graph -> add_edge(from => $name, to => $starter);

} # End of _process_start_rule.

# ----------------------------------------------

sub run
{
	my($self)   = @_;
	my($result) = $self -> parser -> run;

	# Return 0 for success and 1 for failure.

	return $result if ($result == 1);

	# Look over the statements.

	my(@statements) = $self -> parser -> cooked_tree -> daughters;

	my($attributes);
	my(@daughters);
	my($name);
	my($offset);
	my($token);

	for my $i (0 .. $#statements)
	{
		if ($self -> verbose)
		{
			print "i: @{[$i + 1]}. name: ", $statements[$i] -> name, ". \n";
		}

		# Loop over the components of a single statement.

		@daughters  = $statements[$i] -> daughters;
		$name       = $daughters[0] -> name;
		$attributes = $daughters[0] -> attributes;
		$token      = $$attributes{token};

		next if ($name ne 'lhs');

		if ($self -> verbose)
		{
			print "\t1st daughter. name: $name. token: $token. \n";
		}

		if ($token eq 'bare_name')
		{
			if ($daughters[1] -> name eq 'op_declare_bnf')
			{
				$self -> _process_bare_rule(\@daughters);
			}
			else
			{
				$self -> _process_bare_lexeme(\@daughters);
			}
		}
		elsif ($token eq ':default')
		{
			$self -> _process_default_rule(\@daughters);
		}
		elsif ( ($token eq 'discard default') && ($name eq 'lhs') )
		{
			$self -> _process_discard_default_rule(\@daughters);
		}
		elsif ($token eq ':discard')
		{
			$self -> _process_discard_rule(\@daughters);
		}
		elsif ($token eq 'lexeme default')
		{
			$self -> _process_lexeme_default_rule(\@daughters);
		}
		elsif ($token eq ':lexeme')
		{
			$self -> _process_lexeme_rule(\@daughters);
		}
		elsif ($token eq ':start')
		{
			$self -> _process_start_rule(\@daughters);
		}
	}

	$self -> add_legend if ($self -> legend);

	my($output_file) = $self -> output_file;

	if ($output_file)
	{
		$self -> graph -> run(output_file => $output_file);
	}

	# Return 0 for success and 1 for failure.

	return $result;

} # End of run.

# ------------------------------------------------

1;

=pod

=encoding utf8

=head1 NAME

L<MarpaX::Grammar::GraphViz2> - Convert a Marpa grammar into an image

=head1 Synopsis

	use MarpaX::Grammar::GraphViz2;

	my(%option) =
	(		# Inputs:
		legend         => 1,
		marpa_bnf_file => 'share/metag.bnf',
		user_bnf_file  => 'share/stringparser.bnf',
			# Outputs:
		output_file    => 'html/stringparser.svg',
	);

	MarpaX::Grammar::GraphViz2 -> new(%option) -> run;

See share/*.bnf for input files and html/*.svg for output files.

For more help, run:

	shell> perl -Ilib scripts/bnf2graph.pl -h

Note: Installation includes copying all files from the share/ directory, into a dir chosen by
L<File::ShareDir>. Run scripts/find.grammars.pl to display the name of the latter dir.

See also
L<the demo page|http://savage.net.au/Perl-modules/html/marpax.grammar.graphviz2/index.html>.

=head1 Description

For a given BNF, process the cooked tree output by L<MarpaX::Grammar::Parser>, and turn it into an
image.

The tree holds a representation of the user's BNF (SLIF-DSL), and is managed by L<Tree::DAG_Node>.

This modules uses L<MarpaX::Grammar::Parser> internally. It does not read that module's output file.

=head1 Installation

Install L<MarpaX::Grammar::GraphViz2> as you would for any C<Perl> module:

Run:

	cpanm MarpaX::Grammar::GraphViz2

or run:

	sudo cpan MarpaX::Grammar::GraphViz2

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

Note: Installation includes copying all files from the share/ directory, into a dir chosen by
L<File::ShareDir>. Run scripts/find.grammars.pl to display the name of the latter dir.

=head1 Constructor and Initialization

Call C<new()> as C<< my($parser) = MarpaX::Grammar::GraphViz2 -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<MarpaX::Grammar::GraphViz2>.

Key-value pairs accepted in the parameter list (see also the corresponding methods
[e.g. L</marpa_bnf_file([$bnf_file_name])>]):

=over 4

=item o driver aGraphvizDriverName

The name of the Graphviz program to provide to L<GraphViz2>.

Default: 'dot'.

=item o format => $format_name

This is the format of the output file, to be passed to L<GraphViz2>.

Default: 'svg'.

=item o graph => $graphviz2_object

Provides an object of type L<GraphViz2>, to do the rendering.

Default:

	GraphViz2 -> new
	(
		edge   => {color => 'grey'},
		global => {directed => 1, driver => $self -> driver, format => $self -> format},
		graph  => {label => basename($self -> user_bnf_file), rankdir => 'TB'},
		logger => $self -> logger,
		node   => {shape => 'rectangle', style => 'filled'},
	);

=item o legend => $Boolean

Add a legend (1) to the graph, or omit it (0).

Default: 0.

=item o logger => $logger_object

Specify a logger object.

The default value triggers creation of an object of type L<Log::Handler> which outputs to the
screen.

To disable logging, just set I<logger> to the empty string.

The value for I<logger> is passed to L<GraphViz2>.

Default: undef.

=item o marpa_bnf_file aMarpaBNFFileName

Specify the name of Marpa's own BNF file. This file ships with L<Marpa::R2>. It's name is
metag.bnf.

A copy, as of Marpa::R2 V 2.096000, ships with C<MarpaX::Grammar::GraphViz2>. See share/metag.bnf.

This option is mandatory.

Default: ''.

=item o maxlevel => $level

This option is only used if an object of type L<Log::Handler> is created. See I<logger> above.

See also L<Log::Handler::Levels>.

Default: 'notice'. A typical value is 'debug'.

=item o minlevel => $level

This option is only used if an object of type L<Log::Handler> is created. See I<logger> above.

See also L<Log::Handler::Levels>.

Default: 'error'.

No lower levels are used.

=item o output_file => $output_file_name

Write the image to this file.

Use the C<format> option to specify the type of image desired.

If '', the file is not written.

Default: ''.

=item o user_bnf_file aUserBNFFileName

Specify the name of the file containing your Marpa::R2-style grammar.

See share/stringparser.bnf for a sample.

This option is mandatory.

Default: ''.

=back

=head1 Methods

=head2 add_legend()

Adds a legend to the graph if new() was called as C<< new(legend => 1) >>.

=head2 add_node(%attributes)

Adds (once only) a node to the graph. The node's name is C<$attributes{name}>.

Also, adds that name to the hashref of node names seen, which is returned by L</nodes_seen()>.

=head2 clean_name($name, $skip_symbols)

Cleans the given name to escape or replace characters special to L<dot|http://graphviz.org>.

Note: L<GraphViz2> also escapes some characters.

$skip_symbols is used by the caller in 1 case to stop a regexp being activated.

See the L</FAQ> for details.

Returns the cleaned-up name.

=head2 clean_tree()

Calls L</clean_name($name, $skip_symbols)> for each node in the tree.

=head2 default_count()

Returns the number of C<:default>' rules in the user's input.

=head2 discard_count()

Returns the number of C<:discard> rules in the user's input.

=head2 driver([$executable_name])

Here, the [] indicate an optional parameter.

Get or set the name of the Graphviz program to provide to L<GraphViz2>.

Note: C<driver> is a parameter to new().

=head2 event_count()

Returns the number of C<event> rules in the user's input.

=head2 format([$format])

Here, the [] indicate an optional parameter.

Get or set the format of the output file, to be created by the renderer.

Note: C<format> is a parameter to new().

=head2 graph([$graph])

Get of set the L<GraphViz2> object which will do the graphing.

See also L</output_file([$output_file_name])>.

Note: C<graph> is a parameter to new().

=head2 legend([$Boolean])

Here, the [] indicate an optional parameter.

Get or set the option to include (1) or exclude (0) a legend from the image.

Note: C<legend> is a parameter to new().

=head2 lexeme_count()

Returns the number of C<:lexeme> rules in the user's input.

=head2 lexemes()

Returns a hashref keyed by the clean name, of lexemes seen in the user's input.

The value for each key is an arrayref of hashrefs suitable for forcing L<GraphViz2> to plot the node
as a record structure. See L<http://www.graphviz.org/content/node-shapes#record> for the gory
details.

=head2 log($level, $s)

Calls $self -> logger -> log($level => $s) if ($self -> logger).

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set logger to the empty string.

This logger is passed to L<GraphViz2>.

Note: C<logger> is a parameter to new().

=head2 marpa_bnf_file([$bnf_file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file to read Marpa's grammar from.

Note: C<marpa_bnf_file> is a parameter to new().

=head2 maxlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created. See
L<Log::Handler::Levels>.

Note: C<maxlevel> is a parameter to new().

=head2 minlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created. See
L<Log::Handler::Levels>.

Note: C<minlevel> is a parameter to new().

=head2 new()

The constructor. See L</Constructor and Initialization>.

=head2 nodes_seen()

Returns a hashref keyed by the node name, of nodes passed to L<GraphViz2>.

This is simply used to stop nodes being plotted twice.

=head2 output_file([$output_file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file to which the renderer will write the resultant graph.

If no output file is supplied, nothing is written.

See also L<graph([$graph])>.

Note: C<output_file> is a parameter to new().

=head2 parser()

Returns the L<Marpa::Grammar::Parser> object which will do the analysis of the user's grammar.

This object is created automatically during the call to L</new()>.

=head2 rectify_node($node)

For the given $node, which is an object of type L<Tree::DAG_Node>, clean it's real name.

Then it adds the node's quantifier ('', '*' or '+') to that name, to act as the label (visible name)
of the node, when the node is finally passed to L<GraphViz2>.

Returns a 2-element list of ($name, $label).

=head2 root_name()

Returns a string which is the name of the root node of graph.

=head2 run()

The method which does all the work.

See L</Synopsis> and scripts/bnf2graph.pl for sample code.

=head2 user_bnf_file([$bnf_file_name])

Here, the [] indicate an optional parameter.

Get or set the name of the file to read the user's grammar from.

Note: C<user_bnf_file> is a parameter to new().

=head1 Files Shipped with this Module

=head2 Data Files

=over 4

=item o share/c.ast.bnf

This is part of L<MarpaX::Languages::C::AST>, by Jean-Damien Durand. It's 1,565 lines long.

=item o html/c.ast.svg

This is the image from c.ast.bnf.

See the next point for how this file is created.

=item o share/json.1.bnf

It is part of L<MarpaX::Demo::JSONParser>, written as a gist by Peter Stuifzand.

See L<https://gist.github.com/pstuifzand/4447349>.

See the next point for how this file is created.

=item o html/json.1.svg

This is the image from json.1.bnf.

=item o share/json.2.bnf

It also is part of L<MarpaX::Demo::JSONParser>, written by Jeffrey Kegler as a reply to the gist
above from Peter.

=item o html/json.2.svg

This is the image from json.2.bnf.

See the previous point for how this file is created.

=item o share/json.3.bnf

It also is part of L<MarpaX::Demo::JSONParser>, and is written by Jeffrey Kegler.

=item o html/json.3.svg

This is the image from json.3.bnf.

=item o share/metag.bnf.

This is a copy of L<Marpa::R2>'s BNF, as of Marpa::R2 V 2.096000.

=item o html/metag.svg

This is the image from metag.bnf.

=item o share/numeric.expressions.bnf.

This BNF was extracted from L<MarpaX::Demo::SampleScripts>'s examples/ambiguous.grammar.01.pl.

=item o html/numeric.expressions.svg

This is the image from numeric.expressions.bnf.

See the next point for how this file is created.

=item o share/stringparser.bnf.

This is a copy of L<MarpaX::Demo::StringParser>'s BNF.

=item o html/stringparser.svg

This is the image from stringparser.bnf.

See the next point for how this file is created.

=item o share/termcap.info.bnf

It also is part of L<MarpaX::Database::Terminfo>, written by Jean-Damien Durand.

=item o html/termcap.info.svg

This is the image from termcap.info.bnf.

See the next point for how this file is created.

=back

=head2 Scripts

=over 4

=item o scripts/bnf2graph.pl

This is a neat way of using the module. For help, run:

	shell> perl -Ilib scripts/bnf2graph.pl -h

Of course you are also encouraged to include this module directly in your own code.

=item o scripts/bnf2graph.sh

This is a quick way for me to run bnf2graph.pl.

=item o scripts/find.grammars.pl

This prints the path to a grammar file. After installation of the module, run it with:

	shell> perl scripts/find.grammars.pl (Defaults to json.1.bnf)
	shell> perl scripts/find.grammars.pl c.ast.bnf
	shell> perl scripts/find.grammars.pl json.1.bnf
	shell> perl scripts/find.grammars.pl json.2.bnf
	shell> perl scripts/find.grammars.pl stringparser.bnf
	shell> perl scripts/find.grammars.pl termcap.inf.bnf

It will print the name of the path to given grammar file.

=item o scripts/generate.demo.pl

Generates html/index.html.

=item o scripts/generate.demo.sh

This calls generate.demo.pl for each grammar shipped with the module.

Actually, it skips c.ast by default, since it takes 6 m 47 s to run that. But if you pass any
command line parameter to the script, it includes c.ast.

Then it copies html/* to my web server's doc root (which is in Debian's default RAM disk) at
/dev/shm/html.

=item o scripts/pod2html.sh

This lets me quickly proof-read edits to the docs.

=back

=head1 FAQ

=head2 Why are some characters in the images replaced by Unicode versions?

Firstly, the Perl module L<GraphViz2> escapes some characters. Currently, these are:

	[ ] " (in various circumstances)

We let L<GraphViz2> handle these.

Secondly, L<Graphviz|http://graphviz.org> itself treats some characters specially. Currently, these
are:

	< > : "

We use this code to handle these:

	$name =~ s/\\/\\\\/g;             # Escape \.
	$name =~ s/</\\</g;               # Escape <.
	$name =~ s/>/\\>/g;               # Escape >.
	$name =~ s/:/\x{a789}/g;          # Replace : with a Unicode :
	$name =~ s/\"/\x{a78c}\x{a78c}/g; # Replace " with 2 copies of a Unicode ' ...
	                                  # ... because I could not find a Unicode ".

=head2 Why do some images have a tiny sub-graph, whose root is, e.g., '<comma>'?

This is due to the author using both 'comma' and '<comma>' as tokens within the grammar.

So far this module does not notice the two are the same.

A similar thing can happen elsewhere, e.g. with named event statements, when the rhs name uses (say)
'<xyz>'
and the rule referred to uses just 'xyz'.

In all such cases, there will be 2 nodes, with 2 names differing in just the brackets.

=head2 Why do some nodes have (or lack) a quantifier when I use it both with and without one?

There is simply no way to plot a node both with and without the quantifier. The one which appears is
chosen arbitrarily, depending on how the code scans the grammar. This means it is currently beyond
control.

=head2 Why do the nodes on the demo page lack rule numbers?

I'm undecided as to whether or not they are a good idea. I documented it on the demo page to
indicate it was easy (for some nodes), and await feedback.

=head2 Can I control the format or placement of the legend?

No, but you can turn it off with the C<legend> option to C<< new() >>.

=head1 ToDo

=over 4

=item o Perhaps add rule # to each node

This is the rule # within the input stream. Doing this is simple for some nodes, and difficult for
others.

=back

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/MarpaX-Grammar-GraphViz2>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX::Grammar::GraphViz2>.

=head1 Author

L<MarpaX::Grammar::GraphViz2> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

Home page: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
