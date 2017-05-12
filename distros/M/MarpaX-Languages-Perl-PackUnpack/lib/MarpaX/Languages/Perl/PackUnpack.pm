package MarpaX::Languages::Perl::PackUnpack;

use strict;
use utf8;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use open     qw(:std :utf8); # Undeclared streams in UTF-8.

use Config;

use Const::Exporter constants =>
[
	nothing_is_fatal   => 0, # The default.
	debug              => 1,
	print_warnings     => 2,
	ambiguity_is_fatal => 4,
];

use Marpa::R2;

use Moo;

use Tree;

use Types::Standard qw/Any ArrayRef HashRef Int Str/;

use Try::Tiny;

has bnf =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has error_message =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has error_number =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has grammar =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has known_events =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has next_few_limit =>
(
	default  => sub{return 20},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has options =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has recce =>
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

has template =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has tree =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

our $VERSION = '1.00';

# ------------------------------------------------

sub BUILD
{
	my($self) = @_;

	# Policy: Event names are always the same as the name of the corresponding lexeme.
	#
	# Pack syntax reference: http://perldoc.perl.org/functions/pack.html.

	my($bnf) = <<'END_OF_GRAMMAR';

:default				::= action => [values]

lexeme default			= latm => 1

:start					::= template

template				::= item+

# The reason for the rank clauses is to handle cases like 'j'. Because that letter is in
# both bang_or_endian_set and endian_only_set, the parse is ambiguous, and returns a forest
# when there is no rank. In such a case, you get this:
#	Error: Parse failed. value() called when recognizer is not in tree mode
#	  The current mode is "forest"
# Since here is does not matter which way we jump, I've arbitrarily used ranks 1 .. 4.
# AFAIK any ranks will do, as long as they are different.
# BTW: These ranks only work because I've used (ranking_method => 'high_rule_only')
# in the call to the constructor Marpa::R2::Scanless::R -> new().

item					::= prefix character

prefix					::=
prefix					::= percent_literal number

character				::= basic_set										repeat_token	rank => 1
							| bang_only_set			bang_token				repeat_token	rank => 2
							| bang_or_endian_set	bang_or_endian_token	repeat_token	rank => 3
							| endian_only_set		endian_token			repeat_token	rank => 4
							| parentheses_set								repeat_special	rank => 5

repeat_token			::= repeat_item
							| repeat_item slash_literal repeat_item

repeat_item				::= repeat_count
repeat_item				::= open_bracket repeat_flag close_bracket

repeat_count			::= repeat_number
							| star

repeat_number			::=
repeat_number			::= number

repeat_flag				::= repeat_count
							| character

repeat_special			::= repeat_number endian_token
							| endian_token repeat_number

bang_token				::=
bang_token				::= bang_literal

bang_or_endian_set		::= bang_only_set
							| bang_and_endian_set
							| endian_only_set

bang_or_endian_token	::=
bang_or_endian_token	::= bang_literal
							| endian_literal
							| bang_endian_literal

endian_token			::=
endian_token			::= endian_literal

# Lexemes in alphabetical order.

:lexeme					~ bang_and_endian_set	pause => before		event => bang_and_endian_set
bang_and_endian_set		~ [sSiIlL]

:lexeme					~ bang_endian_literal	pause => before		event => bang_endian_literal
bang_endian_literal		~ '!<'
bang_endian_literal		~ '!>'
bang_endian_literal		~ '<!'
bang_endian_literal		~ '>!'

:lexeme					~ bang_literal			pause => before		event => bang_literal
bang_literal			~ '!'

:lexeme					~ bang_only_set			pause => before		event => bang_only_set
bang_only_set			~ [xXnNvV@.]

:lexeme					~ basic_set				pause => before		event => basic_set
basic_set				~ [aAZbBhHcCwWuU]

:lexeme					~ close_bracket			pause => before		event => close_bracket
close_bracket			~ ']'

:lexeme					~ endian_literal		pause => before		event => endian_literal
endian_literal			~ [><]

:lexeme					~ endian_only_set		pause => before		event => endian_only_set
endian_only_set			~ [qQjJfFdDpP]

:lexeme					~ number				pause => before		event => number
number					~ [\d]+

:lexeme					~ open_bracket			pause => before		event => open_bracket
open_bracket			~ '['

:lexeme					~ parentheses_set		pause => before		event => parentheses_set
parentheses_set			~ [()]

:lexeme					~ percent_literal		pause => before		event => percent_literal
percent_literal			~ '%'

:lexeme					~ slash_literal			pause => before		event => slash_literal
slash_literal			~ '/'

:lexeme					~ star					pause => before		event => star
star					~ '*'

:discard				~ whitespace
whitespace				~ [\s]+

:discard				~ <hash style comment>

# Hash comment handling copied from Marpa::R2's metag.bnf.

<hash style comment>				~ <terminated hash comment>
										| <unterminated final hash comment>

<terminated hash comment>			~ '#' <hash comment body> <vertical space char>

<unterminated final hash comment>	~ '#' <hash comment body>

<hash comment body>					~ <hash comment char>*

<vertical space char>				~ [\x{0A}\x{0B}\x{0C}\x{0D}\x{2028}\x{2029}]

<hash comment char>					~ [^\x{0A}\x{0B}\x{0C}\x{0D}\x{2028}\x{2029}]

END_OF_GRAMMAR

	$self -> bnf($bnf);
	$self -> grammar
	(
		Marpa::R2::Scanless::G -> new
		({
			source => \$self -> bnf
		})
	);

	my(%event);

	for my $line (split(/\n/, $self -> bnf) )
	{
		$event{$1} = 1 if ($line =~ /event\s+=>\s+(\w+)/);
	}

	$self -> known_events(\%event);

} # End of BUILD.

# ------------------------------------------------

sub _add_daughter
{
	my($self, $node_name, $lexeme_name, $lexeme) = @_;
	my($stack)  = $self -> stack;
	my($node)   = Tree -> new($node_name);

	$node -> meta({lexeme => $lexeme_name, text => $lexeme});

	$$stack[$#$stack] -> add_child({}, $node);

} # End of _add_daughter.

# -----------------------------------------------

sub format_node
{
	my($self, $options, $node) = @_;
	my($s) = $node -> value;
	$s     .= '. Attributes: ' . $self -> hashref2string($node -> meta) if (! $$options{no_attributes});

	return $s;

} # End of format_node.

# -----------------------------------------------

sub hashref2string
{
	my($self, $hashref) = @_;
	$hashref ||= {};

	return '{' . join(', ', map{qq|$_ => "$$hashref{$_}"|} sort keys %$hashref) . '}';

} # End of hashref2string.

# ------------------------------------------------

sub next_few_chars
{
	my($self, $string, $offset) = @_;
	my($s) = substr($string, $offset, $self -> next_few_limit);
	$s     =~ tr/\n/ /;
	$s     =~ s/^\s+//;
	$s     =~ s/\s+$//;

	return $s;

} # End of next_few_chars.

# -----------------------------------------------

sub node2string
{
	my($self, $options, $is_last_node, $node, $vert_dashes) = @_;
	my($depth)         = $node -> depth;
	my($sibling_count) = defined $node -> is_root ? 1 : scalar $node -> parent -> children;
	my($offset)        = ' ' x 4;
	my(@indent)        = map{$$vert_dashes[$_] || $offset} 0 .. $depth - 1;
	@$vert_dashes      =
	(
		@indent,
		($sibling_count == 0 ? $offset : '   |'),
	);

	$indent[1] = '    ' if ($is_last_node && ($depth > 1) );

	return join('', @indent[1 .. $#indent]) . ($depth ? '   |--- ' : '') . $self -> format_node($options, $node);

} # End of node2string.

# ------------------------------------------------

sub parse
{
	my($self, $string) = @_;

	$self -> stack([]);
	$self -> template($string) if (defined $string);
	$self -> recce
	(
		Marpa::R2::Scanless::R -> new
		({
			grammar        => $self -> grammar,
			ranking_method => 'high_rule_only',
		})
	);

	# Since $self -> stack has not been initialized yet,
	# we can't call _add_pack_daughter() until after this statement.

	$self -> tree(Tree -> new('root') );
	$self -> stack([$self -> tree]);

	# Return 0 for success and 1 for failure.

	my($result) = 0;

	my($message);

	try
	{
		if (defined (my $value = $self -> _process) )
		{
		}
		else
		{
			$result = 1;

			print "Error: Parse failed\n";
		}
	}
	catch
	{
		$result = 1;

		print "Error: Parse failed. ${_}";
	};

	# Return 0 for success and 1 for failure.

	return $result;

} # End of parse.

# ------------------------------------------------

sub _pop_stack
{
	my($self)  = @_;
	my($stack) = $self -> stack;

	pop @$stack;

	$self -> stack($stack);

} # End of _pop_stack.

# ------------------------------------------------

sub _process
{
	my($self)        = @_;
	my($string)      = $self -> template || ''; # Allow for undef.
	my($pos)         = 0;
	my($length)      = length($string);
	my($format)      = "%-20s    %5s    %5s    %5s    %-20s    %-20s\n";
	my($last_event)  = '';
	my(%token_event) =
	(
		bang_and_endian_set => 1,
		bang_only_set       => 1,
		basic_set           => 1,
		endian_only_set     => 1,
		parentheses_set		=> 1,
	);

	if ($self -> options & debug)
	{
		print "Input: $string. Length: $length. \n";
		print sprintf($format, 'Event', 'Start', 'Span', 'Pos', 'Lexeme', 'Comment');
	}

	my($event_name);
	my($lexeme);
	my($message);
	my($node_name);
	my($original_lexeme);
	my($span, $start);
	my($tos);

	# We use read()/lexeme_read()/resume() because we pause at each lexeme.
	# Also, in read(), we use $pos and $length to avoid reading Ruby Slippers tokens (if any).
	# For the latter, see scripts/match.parentheses.02.pl in MarpaX::Demo::SampleScripts.

	for
	(
		$pos = $self -> recce -> read(\$string, $pos, $length);
		($pos < $length);
		$pos = $self -> recce -> resume($pos)
	)
	{
		($start, $span)            = $self -> recce -> pause_span;
		($event_name, $span, $pos) = $self -> _validate_event($string, $start, $span, $pos);
		$lexeme                    = $self -> recce -> literal($start, $span);
		$original_lexeme           = $lexeme;
		$pos                       = $self -> recce -> lexeme_read($event_name);

		die "lexeme_read($event_name) rejected lexeme |$lexeme|\n" if (! defined $pos);

		print sprintf($format, $event_name, $start, $span, $pos, $lexeme, '-') if ($self -> options & debug);

		$node_name = $token_event{$event_name} ? 'token' : $event_name;

		if ( ($node_name eq 'token') && ($#{$self -> stack} > 1) )
		{
			$self -> _pop_stack;
		}

		$self -> _add_daughter($node_name, $event_name, $lexeme);

		$self -> _push_stack if ($node_name eq 'token');

		$last_event = $event_name;
	}

	if (my $status = $self -> recce -> ambiguous)
	{
		my($terminals) = $self -> recce -> terminals_expected;
		$terminals     = ['(None)'] if ($#$terminals < 0);
		$message       = 'Ambiguous parse. Status: $status. Terminals expected: ' . join(', ', @$terminals);

		$self -> error_message($message);
		$self -> error_number(1);

		if ($self -> options & ambiguity_is_fatal)
		{
			# This 'die' is inside try {}catch{}, which adds the prefix 'Error: '.

			die "$message\n";
		}
		elsif ($self -> options & print_warnings)
		{
			$self -> error_number(-1);

			print "Warning: $message\n";
		}
	}

	# Return a defined value for success and undef for failure.

	return $self -> recce -> value;

} # End of _process.

# ------------------------------------------------

sub _push_stack
{
	my($self)      = @_;
	my($stack)     = $self -> stack;
	my(@daughters) = $$stack[$#$stack] -> children;

	push @$stack, $daughters[$#daughters];

	$self -> stack($stack);

} # End of _push_stack.

# ------------------------------------------------

sub size_report
{
	my($self)             = @_;
	my($is_little_endian) = unpack('c',  pack('s', 1) );
	my($is_big_endian)    = unpack('xc', pack('s', 1) );
	my(%size)             =
	(
		1 => ['short',    's!', 'S!', $Config{shortsize}, '$Config{shortsize}'],
		2 => ['int',      'i!', 'I!', $Config{intsize},   '$Config{intsize}'],
		3 => ['long',     'l!', 'L!', $Config{longsize},  '$Config{longsize}'],
		4 => ['longlong', 'q!', 'Q!', $Config{longlongsize} || 'Undef', '$Config{longlongsize}'],
	);

	print "Byte order: $Config{byteorder}. Little endian: $is_little_endian. Big endian: $is_big_endian. \n";
	print "Some template codes and their size requirements: \n";

	my($format) = "%-6s  %-8s  %-10s  %-s  %-s\n";

	print sprintf($format, 'Signed', 'Unsigned', 'Name', 'Byte length in Perl', '');

	for my $key (1 .. 4)
	{
		print sprintf($format, $size{$key}[1], $size{$key}[2], $size{$key}[0], $size{$key}[3], $size{$key}[4]);
	}

} # End of size_report.

# ------------------------------------------------

sub template_report
{
	my($self)     = @_;
	my($count)    = 0;
	my($previous) = '';
	my($result)   = '';

	my($attributes);
	my($text);

	for my $node ($self -> tree -> traverse)
	{
		next if ($node -> is_root);

		$count++;

		$attributes = $node -> meta;
		$text       = $$attributes{text};
		$result     .= ' ' if ( ($count > 1) && ($previous ne '/') && ($node -> value eq 'token') );
		$result     .= $text;
		$previous   = $text;
	}

	return $result;

} # End of template_report.

# -----------------------------------------------

sub tree2string
{
	my($self, $options, $tree) = @_;
	$options                   ||= {};
	$$options{no_attributes}   ||= 0;
	$tree                      ||= $self -> tree;
	my(@nodes)                 = $tree -> traverse;

	my(@out);
	my(@vert_dashes);

	for my $i (0 .. $#nodes)
	{
		push @out, $self -> node2string($options, $i == $#nodes, $nodes[$i], \@vert_dashes);
	}

	return [@out];

} # End of tree2string.

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

	print $message, join(', ', @event_name), "\n" if ($self -> options & debug);

	my(%event_name);

	@event_name{@event_name} = (1) x @event_name;

	for (@event_name)
	{
		if (! ${$self -> known_events}{$_})
		{
			$message = "Unexpected event name '$_'";

			$self -> error_message($message);
			$self -> error_number(2);

			# This 'die' is inside try {}catch{}, which adds the prefix 'Error: '.

			die "$message\n";
		}
	}

	if ($event_count > 1)
	{
		$message = join(', ', @event_name);
		$message = "The code does not handle these events simultaneously: $message";

		$self -> error_message($message);
		$self -> error_number(3);

		# This 'die' is inside try {}catch{}, which adds the prefix 'Error: '.

		die "$message\n";
	}

	return ($event_name, $span, $pos);

} # End of _validate_event.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<MarpaX::Languages::Perl::PackUnpack> - Parse the templates used in pack() and unpack()

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use MarpaX::Languages::Perl::PackUnpack ':constants';

	# -----------

	my($parser) = MarpaX::Languages::Perl::PackUnpack -> new(options => print_warnings);
	my(@text)   =
	(
		qq|n/a* # Newline
	w/a2|,
		q|a3/A A*|,
		q|i9pl|,
	);

	my($result);

	for my $text (@text)
	{
		print "Parsing: $text. \n";

		$result = $parser -> parse($text);

		print join("\n", @{$parser -> tree2string}), "\n";
		print "Parse result: $result (0 is success)\n";
		print 'Template: ', $parser -> template_report, ". \n";
		print '-' x 50, "\n";
	}

	print "\n";

	$parser -> size_report;

See scripts/synopsis.pl.

This is the output of synopsis.pl:

	Parsing: n/a* # Newline
	w/a2.
	root. Attributes: {}
	   |--- token. Attributes: {lexeme => "bang_only_set", text => "n"}
	   |   |--- slash_literal. Attributes: {lexeme => "slash_literal", text => "/"}
	   |   |--- token. Attributes: {lexeme => "basic_set", text => "a"}
	   |   |   |--- star. Attributes: {lexeme => "star", text => "*"}
	   |   |--- token. Attributes: {lexeme => "basic_set", text => "w"}
	   |   |   |--- slash_literal. Attributes: {lexeme => "slash_literal", text => "/"}
	   |   |--- token. Attributes: {lexeme => "basic_set", text => "a"}
	       |   |--- number. Attributes: {lexeme => "number", text => "2"}
	Parse result: 0 (0 is success)
	Template: n/a* w/a2.
	--------------------------------------------------
	Parsing: a3/A A*.
	root. Attributes: {}
	   |--- token. Attributes: {lexeme => "basic_set", text => "a"}
	   |   |--- number. Attributes: {lexeme => "number", text => "3"}
	   |   |--- slash_literal. Attributes: {lexeme => "slash_literal", text => "/"}
	   |   |--- token. Attributes: {lexeme => "basic_set", text => "A"}
	   |   |--- token. Attributes: {lexeme => "basic_set", text => "A"}
	       |   |--- star. Attributes: {lexeme => "star", text => "*"}
	Parse result: 0 (0 is success)
	Template: a3/A A*.
	--------------------------------------------------
	Parsing: i9pl.
	root. Attributes: {}
	   |--- token. Attributes: {lexeme => "bang_and_endian_set", text => "i"}
	   |   |--- number. Attributes: {lexeme => "number", text => "9"}
	   |   |--- token. Attributes: {lexeme => "endian_only_set", text => "p"}
	       |--- token. Attributes: {lexeme => "bang_and_endian_set", text => "l"}
	Parse result: 0 (0 is success)
	Template: i9 p l.
	--------------------------------------------------

	Size report:
	Byte order: 12345678. Little endian: 1. Big endian: 0.
	Some template codes and their size requirements:
	Signed  Unsigned  Name        Byte length in Perl
	s!      S!        short       2  $Config{shortsize}
	i!      I!        int         4  $Config{intsize}
	l!      L!        long        8  $Config{longsize}
	q!      Q!        longlong    8  $Config{longlongsize}

=head1 Description

L<MarpaX::Languages::Perl::PackUnpack> provides a L<Marpa::R2>-based parser for parsing the
templates used in pack() and unpack().

The parsed details are stored in a L<Tree>, and can be accessed via the methods
L</tree2string($options, [$some_tree])> and L</template_report>. The tree itself can be accessed
with the method L</tree()>.

Policy: Event names are always the same as the name of the corresponding lexeme. So any reference to
'event name' is the same as to 'lexeme name', and visa versa. This can be seen in the grammar where
every lexeme which is not discarded is associated with an event of the same name. This matter is
discussed in detail under the question L<FAQ/How is the parsed data held in RAM?>.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<MarpaX::Languages::Perl::PackUnpack> as you would any C<Perl> module:

Run:

	cpanm MarpaX::Languages::Perl::PackUnpack

or run:

	sudo cpan MarpaX::Languages::Perl::PackUnpack

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

C<new()> is called as C<< my($parser) = MarpaX::Languages::Perl::PackUnpack -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<MarpaX::Languages::Perl::PackUnpack>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</template([$string])>]):

=over 4

=item o next_few_limit => $integer

This controls how many characters are printed when displaying 'the next few chars'.

It only affects debug output.

Default: 20.

=item o options => $bit_string

This allows you to turn on various options.

Default: 0 (nothing is fatal).

See the L</FAQ> for details.

=item o template => $string

Specify the string to be parsed.

Default: ''.

=back

=head1 Methods

=head2 bnf()

Returns a string containing the grammar.

=head2 error_message()

Returns the last error or warning message set.

Error messages always start with 'Error: '. Messages never end with "\n".

Parsing error strings is not a good idea, ever though this module's format for them is fixed.

See L</error_number()>.

=head2 error_number()

Returns the last error or warning number set.

Warnings have values < 0, and errors have values > 0.

If the value is > 0, the message has the prefix 'Error: ', and if the value is < 0, it has the
prefix 'Warning: '. If this is not the case, it's a reportable bug.

Possible values for error_number() and error_message():

=over 4

=item o 0 => ""

This is the default value.

=item o 1/-1 => "Ambiguous parse. Status: $status. Terminals expected: a, b, ..."

This message is only produced when the parse is ambiguous.

If L</error_number()> returns 1, it's an error, and if it returns -1 it's a warning.

You can set the option C<ambiguity_is_fatal> to make it fatal.

=item o 2 => "Unexpected event name 'xyz'"

Marpa has trigged an event and it's name is not in the hash of event names derived from the BNF.

This message can never be just a warning message.

=item o 3 => "The code does not handle these events simultaneously: a, b, ..."

The code is written to handle single events at a time, or in rare cases, 2 events at the same time.
But here, multiple events have been triggered and the code cannot handle the given combination.

This message can never be just a warning message.

=back

See L</error_message()>.

=head2 format_node($options, $node)

Returns a string consisting of the node's name and, optionally, it's attributes.

Possible keys in the $options hashref:

=over 4

=item o no_attributes => $Boolean

If 1, the node's attributes are not included in the string returned.

Default: 0 (include attributes).

=back

Calls L</hashref2string($hashref)>.

Called by L</node2string($options, $is_last_node, $node, $vert_dashes)>.

You would not normally call this method.

If you don't wish to supply options, use format_node({}, $node).

=head2 hashref2string($hashref)

Returns the given hashref as a string.

Called by L</format_node($options, $node)>.

=head2 known_events()

Returns a hashref where the keys are event names and the values are 1.

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.

=head2 next_few_chars($string, $offset)

Returns a substring of $s, starting at $offset, for use in debug messages.

See L<next_few_limit([$integer])>.

=head2 next_few_limit([$integer])

Here, the [] indicate an optional parameter.

Get or set the number of characters called 'the next few chars', which are printed during debugging.

'next_few_limit' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 node2string($options, $is_last_node, $node, $vert_dashes)

Returns a string of the node's name and attributes, with a leading indent, suitable for printing.

Possible keys in the $options hashref:

=over 4

=item o no_attributes => $Boolean

If 1, the node's attributes are not included in the string returned.

Default: 0 (include attributes).

=back

Ignore the parameter $vert_dashes. The code uses it as temporary storage.

Calls L</format_node($options, $node)>.

Called by L</tree2string($options, [$some_tree])>.

=head2 options([$bit_string])

Here, the [] indicate an optional parameter.

Get or set the option flags.

For typical usage, see scripts/synopsis.pl.

See the L</FAQ> for details.

'options' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 parse([$string])

Here, the [] indicate an optional parameter.

This is the only method the user needs to call. All data can be supplied when calling L</new()>.

You can of course call other methods (e.g. L</template([$string])> ) after calling L</new()> but
before calling C<parse()>.

Note: If a string is passed to C<parse()>, it takes precedence over any string passed to
C<< new(template => $string) >>, and over any string passed to L</template([$string])>. Further,
the string passed to C<parse()> is passed to L</template([$string])>, meaning any subsequent
call to C<template()> returns the string passed to C<parse()>.

See scripts/samples.pl.

Returns 0 for success and 1 for failure.

If the value is 1, you should call L</error_number()> to find out what happened.

=head2 size_report()

Prints some statistics for the sizes of various integers (short, int, long, etc).

See scripts/synopsis.pl.

=head2 template([$string])

Here, the [] indicate an optional parameter.

Get or set the string to be parsed.

'template' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 template_report

Get the string output from the parse. The code generates this string by walking the nodes of the
L<Tree> returned by a call to C<< $self -> tree() >>.

Apart from perhaps spacing, it will be identical to the string passed in to be parsed.

See t/test.t.

=head2 tree()

Returns an object of type L<Tree>, which holds the parsed data.

Obviously, it only makes sense to call C<tree()> after calling L</parse([$string])>.

See scripts/traverse.pl for sample code which processes this tree's nodes.

If you wish to save the tree before calling L</parse([$string])> again, call:

	my($tree) = $parser -> tree -> clone();

Later you can then do this to process $tree instead of $parser's tree:

	print join("\n", @{$parser -> tree2string({}, $tree)}), "\n";

=head2 tree2string($options, [$some_tree])

Here, the [] represent an optional parameter.

If $some_tree is not supplied, uses the calling object's tree ($self -> tree).

Returns an arrayref of lines, suitable for printing. These lines do not end in "\n".

Draws a nice ASCII-art representation of the tree structure.

The tree looks like:

	Root. Attributes: {# => "0"}
	   |--- I. Attributes: {# => "1"}
	   |   |--- J. Attributes: {# => "3"}
	   |   |   |--- K. Attributes: {# => "3"}
	   |   |--- J. Attributes: {# => "4"}
	   |       |--- L. Attributes: {# => "5"}
	   |           |--- M. Attributes: {# => "5"}
	   |               |--- N. Attributes: {# => "5"}
	   |                   |--- O. Attributes: {# => "5"}
	   |--- H. Attributes: {# => "2"}
	   |   |--- J. Attributes: {# => "3"}
	   |   |   |--- K. Attributes: {# => "3"}
	   |   |--- J. Attributes: {# => "4"}
	   |       |--- L. Attributes: {# => "5"}
	   |           |--- M. Attributes: {# => "5"}
	   |               |--- N. Attributes: {# => "5"}
	   |                   |--- O. Attributes: {# => "5"}

Or, without attributes:

	Root
	   |--- I
	   |   |--- J
	   |   |   |--- K
	   |   |--- J
	   |       |--- L
	   |           |--- M
	   |               |--- N
	   |                   |--- O
	   |--- H
	   |   |--- J
	   |   |   |--- K
	   |   |--- J
	   |       |--- L
	   |           |--- M
	   |               |--- N
	   |                   |--- O

See scripts/samples.pl.

Example usage:

	print map("$_\n", @{$tree -> tree2string});

Can be called with $some_tree set to any $node, and will print the tree assuming $node is the root.

If you don't wish to supply options, use tree2string({}, $node).

Possible keys in the $options hashref (which defaults to {}):

=over 4

=item o no_attributes => $Boolean

If 1, the node's attributes are not included in the string returned.

Default: 0 (include attributes).

=back

Calls L</node2string($options, $is_last_node, $node, $vert_dashes)>.

=head1 FAQ

=head2 Where are the error messages and numbers described?

See L</error_message()> and L</error_number()>.

=head2 What are the possible values for the 'options' parameter to new()?

Firstly, to make these constants available, you must say:

	use MarpaX::Languages::Perl::PackUnpack ':constants';

Secondly, more detail on errors and warnings can be found at L</error_number()>.

Thirdly, for usage of these option flags, see scripts/*.pl.

Now the flags themselves:

=over 4

=item o nothing_is_fatal

This is the default.

It's value is 0.

=item o debug

Print extra stuff if this flag is set.

It's value is 1.

=item o print_warnings

Print various warnings if this flag is set:

=over 4

=item o The ambiguity status and terminals expected, if the parse is ambiguous

=item o See L</error_number()> for other warnings which might be printed

Ambiguity is not, in and of itself, an error. But see the C<ambiguity_is_fatal> option, below.

=back

It's tempting to call this option C<warnings>, but Perl already has C<use warnings>, so I didn't.

It's value is 2.

=item o ambiguity_is_fatal

This makes L</error_number()> return 1 rather than -1.

It's value is 4.

=back

=head2 How do I print the tree built by the parser?

See L</Synopsis>.

=head2 How do I make use of the tree built by the parser?

See scripts/traverse.pl.

=head2 How is the parsed data held in RAM?

The parsed output is held in a tree managed by L<Tree>.

The tree always has a root node, which has nothing to do with the input data. So, even an empty
imput string will produce a tree with 1 node. This root has an empty hashref associated with it.

Nodes have a name (accessed with the C<value()> method) and a hashref of attributes (accessed
with the C<meta()> method).

The name indicates the type of node. Names are one of these literals:

=over 4

=item o 'token'

If the node's name is 'token', then the node represents one of the template characters listed in the
first table in L<the docs for pack()|http://perldoc.perl.org/functions/pack.html>. Note: both
'(' and ')' are called 'token'.

=item o $lexeme_name

This means all other lexemes identified in the parse have as their node name the name of a lexeme
as given in the grammar returned by the L</bnf()> method. The actual lexeme in question is the one
used to identify a substring of the input template.

=back

See the following hashref for details.

For each node, the attributes hashref contains 2 keys:

=over 4

=item o lexeme => $lexeme_name

This is always $lexeme_name (as just above), even in those cases where the node's name
is 'token'.

=item o text => $text

This is a substring from the template being parsed. The exact contents and length of this string
depend on which lexeme in the input template was recognised, which is identified by the value
of the 'lexeme' key.

=back

See scripts/traverse.pl, which prints a few trees differently than what happens when
L</tree2string($options, [$some_tree])> is called.

=head2 What is the homepage of Marpa?

L<http://savage.net.au/Marpa.html>.

That page has a long list of links.

=head2 How do I run author tests?

This runs both standard and author tests:

	shell> perl Build.PL; ./Build; ./Build authortest

=head1 See Also

L<The docs for pack()|http://perldoc.perl.org/functions/pack.html>.

L<The pack()/unpack() tutorial|http://perldoc.perl.org/perlpacktut.html>.

L<The docs for unpack()|http://perldoc.perl.org/functions/unpack.html>.

L<Tree> and L<Tree::Persist>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/MarpaX-Languages-Perl-Pack>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX::Languages::Perl::PackUnpack>.

=head1 Author

L<MarpaX::Languages::Perl::PackUnpack> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2015.

Marpa's homepage: L<http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2015, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut
