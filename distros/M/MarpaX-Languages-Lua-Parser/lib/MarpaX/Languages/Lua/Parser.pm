package MarpaX::Languages::Lua::Parser;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::RenderAsTree;

use Data::Section::Simple 'get_data_section';

use Log::Handler;

use Marpa::R2;

use Moo;

use Path::Tiny; # For path().

use Types::Standard qw/Any ArrayRef HashRef Bool Str/;

has attributes =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Bool,
	required => 0,
);

has grammar =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has input_file_name =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 1,
);

has input_text =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 1,
);

has keywords =>
(
    default  => sub
	{
		return
		{
			map { $_ => 1 }
			qw
			{
				and       break     do        else      elseif
				end       false     for       function  if
				in        local     nil       not       or
				repeat    return    then      true      until     while
			}
		}
	},
    is       => 'ro',
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

has output_file_name =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 1,
);

has output_tokens =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 1,
);

has recce =>
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

has value =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

# This flag is used to stop Perl issuing deep recursion warnings,
# when Tree::DAG_Node's walk_down() traverses the parse tree.

my($sig_warn_flag) = 1;

our $VERSION = '1.05';

# ------------------------------------------------

sub BUILD
{
	my($self)        = @_;
	$SIG{'__WARN__'} = sub { warn $_[0] if $sig_warn_flag};

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
				utf8           => 1,
			}
		);
	}

	$self -> input_text([path($self -> input_file_name) -> lines_utf8]);
	$self -> grammar
	(
		Marpa::R2::Scanless::G -> new({source => \get_data_section('Lua.bnf')})
	);
	$self -> recce
	(
		Marpa::R2::Scanless::R -> new
		({
			grammar        => $self -> grammar,
			ranking_method => 'high_rule_only',
		})
	);
	$self -> renderer
	(
		Data::RenderAsTree -> new(clean_nodes => 1)
	);

} # End of BUILD.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;
	$level = 'notice' if (! defined $level);
	$s     = ''       if (! defined $s);

	$self -> logger -> $level($s) if ($self -> logger);

} # End of log.

# ------------------------------------------------

sub process
{
	my($self)         = @_;
	my($input)        = join('', @{$self -> input_text});
	my($input_ref)    = \$input;
	my($input_length) = length $input;
	my($pos)          = $self -> recce -> read($input_ref);

	READ: while (1)
	{
		EVENT:
		for my $event (@{$self -> recce -> events})
		{
			my($name) = @{$event};

			if ($name eq 'multiline string' )
			{
				my($start, $length)    = $self -> recce -> pause_span;
				my($string_terminator) = $self -> recce -> literal($start, $length);
				$string_terminator     =~ tr/\[/\]/;
				my($terminator_pos)    = index($$input_ref, $string_terminator, $start);

				die "Died looking for $string_terminator. \n" if ($terminator_pos < 0);

				# The string terminator has the same length as the start of string marker.

				my($string_length) = $terminator_pos + $length - $start;

				$self -> recce -> lexeme_read('multiline string', $start, $string_length);

				$pos = $terminator_pos + $length;

				next EVENT;
			}

			if ($name eq 'multiline comment')
			{
				# This is a discard event.

				my(undef, $start, $end)	= @{$event};
				my($length)				= $end - $start;
				my($comment_terminator)	= $self -> recce -> literal($start, $length);
				$comment_terminator		= ']' . ('=' x ($length - 4)) . ']';
				my($terminator_pos)		= index( $$input_ref, $comment_terminator, $start);

				die "Died looking for $comment_terminator. \n" if ($terminator_pos < 0);

				# Don't read anything into G1 -- just throw the comment away.

				$pos = $terminator_pos + length $comment_terminator;

				next EVENT;
			}

			if ($name eq 'singleline comment')
			{
				# This is a discard event.

				my(undef, $start, $end) = @{$event};
				my($length)             = $end-$start;
				pos($$input_ref)        = $end - 1;
				$$input_ref             =~ /[\r\n]/gxms;
				my($new_pos)            = pos($$input_ref);

				die "Died looking for singleline comment terminator. \n" if (! defined $new_pos);

				$pos = $new_pos;

				next EVENT;
			}

            if ($name eq 'Name')
            {
                # This is an event to check if a keyword is used as an identifier
                # and die if it is.

                my($start, $length) = $self -> recce -> pause_span;
                my($line,  $column) = $self -> recce -> line_column($start);
                my($literal)        = $self -> recce -> literal($start, $length);

				if ( exists $self -> keywords -> { $literal } )
				{
					$self -> recce -> lexeme_read(qq{keyword $literal}, $start, $length)
					// die $self->input_file_name . qq{ (line, column) = ($line, $column): keyword '$literal' used as <name>\n};
                }
                else
                {
                    $self -> recce -> lexeme_read('Name', $start, $length);
                }

                $pos = $self -> recce -> pos();

                next EVENT;
            }

			die "Unexpected event '$name'\n";

		}

		last READ if ($pos >= $input_length);

		$pos = $self -> recce -> resume($pos);
	}

	# Warning: Don't use if (my($ambiguous_status) = $self -> recce -> ambiguous),
	# since then the 'if' always returns true.

	if (my $ambiguous_status = $self -> recce -> ambiguous)
	{
		die "The Lua source is ambiguous: $ambiguous_status. \n";
	}

	return $self -> recce -> value;

} # End of process.

# --------------------------------------------------

sub render
{
	my($self)      = @_;
	my($slim_list) = [];
	$sig_warn_flag = 0;

	my($attributes);
	my($name);
	my($s);
	my($type);

	$self -> renderer -> root -> walk_down
	({
		callback => sub
		{
			my($node, $opt) = @_;

			# Ignore the root, and keep walking.

			return 1 if ($node -> is_root);

			$name       = $node -> name;
			$name       =~ s/^\s*\d+\s=\s(.+)/$1/;
			$name       =~ s/\s\[[A-Z]+\s\d+\]//;
			$attributes = $node -> attributes;
			$type       = $$attributes{type};

			if ($type eq 'SCALAR')
			{
				push @$slim_list, $name;

				$self -> log(info => ' ' x $$opt{_depth} . $name);
			}

			return 1; # Keep walking.
		},
		_depth => 0,
	});

	$self -> output_tokens($slim_list);

} # End of render.

# ------------------------------------------------

sub run
{
	my($self, %args) = @_;
	my($file_name)   = $args{input_file_name} || $self -> input_file_name;
	$sig_warn_flag   = 0; # Turn off Perl's warnings for the duration of tree processing.

	$self -> value($self -> process($file_name) );
	$self -> renderer -> run(${$self -> value});
	$self -> log(debug => $_) for @{$self -> renderer -> root -> tree2string({no_attributes => 1 - $self -> attributes})};
	$self -> render;

	$sig_warn_flag = 1; # Turn Perl's warnings back on.

	my($output_file_name) = $args{output_file_name} || $self -> output_file_name;

	if ($output_file_name)
	{
		path($output_file_name) -> spew_utf8(map{"$_\n"} @{$self -> output_tokens});
	}

	# Return 0 for success and 1 for failure.

	return 0;

} # End of run.

#-------------------------------------------------

1;

=pod

=head1 NAME

C<MarpaX::Languages::Lua::Parser> - A Lua source code parser

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use MarpaX::Languages::Lua::Parser;

	# ---------------------------------

	my($input_file_name) = shift || die "Usage: $0 a_lua_source_file_name\n";
	my($parser)          = MarpaX::Languages::Lua::Parser -> new(input_file_name => $input_file_name);

	$parser -> run;

	print map{"$_\n"} @{$parser -> output_tokens};

This script ships as scripts/synopsis.pl. Run it as:

	shell> perl -Ilib scripts/synopsis.pl lua.sources/echo.lua

See also scripts/parse.file.pl for code which takes command line parameters. For help, run:

	shell> perl -Ilib scripts/parse.file.pl -h

=head1 Description

C<MarpaX::Languages::Lua::Parser> parses Lua source code files.

The result is stored in a tree managed by L<Tree::DAG_Node>.

A list of scalar tokens from this tree is stored in an arrayref.

See the FAQ question L</How do I get output from this module?> for details.

=head1 Installation

Install C<MarpaX::Languages::Lua::Parser> as you would for any C<Perl> module:

Run:

	cpanm MarpaX::Languages::Lua::Parser

or run:

	sudo cpan MarpaX::Languages::Lua::Parser

or unpack the distro, and then:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = MarpaX::Languages::Lua::Parser -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<MarpaX::Languages::Lua::Parser>.

Key-value pairs accepted in the parameter list (see also the corresponding methods
[e.g. L</input_file_name([$string])>]):

=over 4

=item o attributes => $Boolean

When set to 1, metadata attached to each tree node is included in the output.

If you set the L</maxlevel()> to 'debug', this tree is printed to the log.

Default: 0.

=item o input_file_name => $string

The name the input file to be parsed.

This option is mandatory.

Default: ''.

=item o logger => aLog::HandlerObject

By default, an object of type L<Log::Handler> is created which prints to STDOUT,
but given the default setting (maxlevel => 'notice'), nothing is actually printed.

See C<maxlevel> and C<minlevel> below.

Set C<logger> to '' (the empty string) to stop a logger being created.

Default: undef.

=item o maxlevel => logOption1

This option affects L<Log::Handler> objects.

See the L<Log::Handler::Levels> docs.

Typical values: 'info', 'debug'.

See the FAQ question L</How do I get output from this module?> for details.

See also the help output by scripts/parse.file.pl -h.

Default: 'notice'.

=item o minlevel => logOption2

This option affects L<Log::Handler> object.

See the L<Log::Handler::Levels> docs.

Default: 'error'.

No lower levels are used.

=item o output_file_name => $string

The name  of the text file to be written.

If not set, nothing is written.

The items written, one per line, are as returned by L</output_tokens>.

Default: ''.

=back

=head1 Methods

=head2 attributes([$Boolean])

Here, the [] indicate an optional parameter.

Gets or sets the attributes option.

Note: The value passed to L<Tree::DAG_Node>'s C<tree2string()> method is (1 - $Boolean).

See the FAQ question L</How do I get output from this module?> for details.

C<attributes> is a parameter to L</new()>.

=head2 input_file_name([$string])

Here, the [] indicate an optional parameter.

Get or set the name of the file to parse.

See lua.sources/*.lua for sample input.

Note: C<input_file_name> is a parameter to new().

=head2 log($level, $s)

Calls $self -> logger -> log($level => $s) if ($self -> logger).

=head2 logger([$log_object])

Here, the [] indicate an optional parameter.

Get or set the log object.

C<$log_object> must be a L<Log::Handler>-compatible object.

To disable logging, just set logger to the empty string.

Note: C<logger> is a parameter to new().

=head2 maxlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created. See L<Log::Handler::Levels>.

Typical values: 'info', 'debug'.

See the FAQ question L</How do I get output from this module?> for details.

Note: C<maxlevel> is a parameter to new().

=head2 minlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created. See L<Log::Handler::Levels>.

Note: C<minlevel> is a parameter to new().

=head2 new()

This method is auto-generated by L<Moo>.

=head2 output_file_name([$string])

Here, the [] indicate an optional parameter.

Get or set the name of the file to write.

The tokens written are as returned from L</output_tokens>.

Note: C<output_file_name> is a parameter to new().

=head2 output_tokens()

Returns an arrayref of tokens output by the parse, one per line. These tokens are pushed onto the
stack by walking the tree returned by the renderer, which is an object of type
L<Data::RenderAsTree>. The renderer is run by passing it the output from the call to Marpa's
C<value()> method. See L</renderer()>.

If you set the L</maxlevel()> to 'info', these tokens are printed to the log.

See scripts/synopsis.pl for accessing this arrayref.

See lua.output/*.txt for sample output.

=head2 renderer()

Returns the object of type L<Data::RenderAsTree>, which takes the output from the call to Marpa's
C<value()> method and converts it into an object of type L</Tree::DAG_Node>.

If you set the L</maxlevel()> to 'debug', this tree is printed to the log.

=head2 run([%args])

The method which does all the work.

C<%args> is a hash with this optional (key => value) pair:

=over 4

=item o input_file_name => $in_file_name

=item o output_file_name => $out_file_name

=back

File names specified in the call to C<run()> take precedence over file names specified to L</new()>.

Returns 0 for a successful parse and 1 for failure.

The code dies if L<Marpa::R2> itself can't parse the given input file.

Note: C<input_file_name> and C<output_file_name> are parameters to L</new()>.

=head1 FAQ

=head2 Why did you store Lua's BNF in a __DATA__ section?

This avoids problems with single- and double-quotes in the BNF, and the allegedly unknown escape
sequences \v etc too.

=head2 How do I get output from this module?

In various ways:

=over 4

=item o Call the L</output_tokens()> method

Then, process the arrayref returned.

=item o Call the L</renderer()> method

This will return an object of type L<Data::RenderAsTree>, and from there you can call that object's
C<root()> method, to get access to the tree itself. See this module's C<render()> method for sample
code.

=item o Set maxlevel to 'info'.

This writes the output tokens to the log, one per line.

See the C<render()> method for sample code.

=item o Set maxlevel to 'debug'.

This writes the output tokens to the log, one per line, and also writes to the log the tree
returned by passing the return value of Marpa's C<value()> method to the renderer. The renderer
is an object of type L<Data::RenderAsTree>, and outputs a tree managed by L<Tree::DAG_Node>.

See the L</run([%args])> method for sample code.

=item o Set the output_file_name to a non-empty string

In this case the code will walk the tree just mentioned, and output the scalar items, one per line,
to this file.

=item o All of the above

=back

=head2 How do I interpret the output?

For help with this, try the IRC channel irc.freenode.net#marpa.

What that really means is that neither Jeffrey no anyone else imposes any kind of restriction on
what you may do with the output, or with how you may interpret it.

=head2 Where is Marpa's home page?

L<http://savage.net.au/Marpa.html>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/MarpaX-Languages-Lua-Parser>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX::Languages::Lua::Parser>.

=head1 Credits

Jeffrey Kegler wrote the code, and posted a link on the IRC chat channel mentioned above.

See L<http://irclog.perlgeek.de/marpa/2015-06-13>.

=head1 Author

L<MarpaX::Languages::Lua::Parser> was packaged by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2015.

Homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2015, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut

__DATA__

@@ Lua.bnf

:default ::= action => [name,values]

lexeme default = latm => 1 action => [name,values]

# I (JK)  attempt to follow the order of the Lua grammar in
# section 8 of the Lua 5.1 reference manual.
#
# Names which begin with "Lua" are taken directly from
# the Lua reference manual grammar.

<chunk> ::=
<chunk> ::= <stat list>
<chunk> ::= <stat list> laststat
<chunk> ::= <stat list> laststat ';'
<chunk> ::= laststat ';'
<chunk> ::= laststat

<stat list> ::= <stat>
<stat list> ::= <stat> ';'
<stat list> ::= <stat list> <stat> rank => -1
<stat list> ::= <stat list> <stat> ';'

<block> ::= <chunk>

<stat> ::= <varlist> '=' <explist>

<stat> ::= <functioncall> rank => -1

<stat> ::= <keyword do> <block> <keyword end>

<stat> ::= <keyword while> <exp> <keyword do> <block> <keyword end>

<stat> ::= <keyword repeat> <block> <keyword until> <exp>

<stat> ::= <keyword if> <exp> <keyword then> <block>
    <elseif sequence> <optional else block> <keyword end>

<elseif sequence> ::= <elseif sequence> <elseif block>
<elseif sequence> ::=
<elseif block> ::= <keyword elseif> <exp> <keyword then> <block>

<optional else block> ::= <keyword else> <block>
<optional else block> ::=

<stat> ::= <keyword for> <Name> '=' <exp> ',' <exp> ',' <exp>
    <keyword do> <block> <keyword end>

<stat> ::= <keyword for> <Name> '=' <exp> ',' <exp> <keyword do> <block> <keyword end>

<stat> ::= <keyword for> <namelist> <keyword in> <explist> <keyword do> <block> <keyword end>

<stat> ::= <keyword function> <funcname> <funcbody>

<stat> ::= <keyword local> <keyword function> <Name> <funcbody>

<stat> ::= <keyword local> <namelist> <optional namelist initialization>

<optional namelist initialization> ::=
<optional namelist initialization> ::= '=' <explist>

<laststat> ::= <keyword return> <optional explist>
<laststat> ::= <keyword break>

<optional explist> ::=
<optional explist> ::= <explist>

<funcname> ::= <dotted name> <optional colon name element>

<dotted name> ::= <Name>+ separator => [.] proper => 1

<optional colon name element> ::=
<optional colon name element> ::= ':' <Name>

<varlist> ::= <var>+ separator => [,] proper => 1

<var> ::= <Name>
<var> ::= <prefixexp> '[' <exp> ']'
<var> ::= <prefixexp> '.' <Name>

<namelist> ::= <Name>+ separator => [,] proper => 1

<explist> ::= <exp>+ separator => [,] proper => 1

<exp> ::=
		<var>
	 | '(' <exp> ')' assoc => group
	|| <exp> <args> assoc => right
	|| <exp> ':' <Name> <args> assoc => right
	 | <keyword nil>
	 | <keyword false>
	 | <keyword true>
	 | <Number>
	 | <String>
	 | '...'
	 | <tableconstructor>
	 | <function>
	|| <exp> '^' <exponent> assoc => right
	|| '-' <exp>
	 | <keyword not> <exp>
	 | '#' <exp>
	|| <exp> '*' <exp>
	 | <exp> '/' <exp>
	 | <exp> '%' <exp>
	|| <exp> '+' <exp>
	 | <exp> '-' <exp>
	|| <exp> '..' <exp> assoc => right
	|| <exp> '<' <exp>
	 | <exp> '<=' <exp>
	 | <exp> '>' <exp>
	 | <exp> '>=' <exp>
	 | <exp> '==' <exp> rank => 1
	 | <exp> '~=' <exp>
	|| <exp> <keyword and> <exp> rank => 1
	|| <exp> <keyword or> <exp>

<exponent> ::=
		<var>
	 | '(' <exp> ')'
	|| <exponent> <args>
	|| <exponent> ':' <Name> <args>
	 | <keyword nil>
	 | <keyword false>
	 | <keyword true>
	 | <Number>
	 | <String>
	 | '...'
	 | <tableconstructor>
	 | <function>
	|| <keyword not> <exponent>
	 | '#' <exponent>
	 | '-' <exponent>

<prefixexp> ::= <var>
<prefixexp> ::= <functioncall>
<prefixexp> ::= '(' <exp> ')'

<functioncall> ::= <prefixexp> <args>
<functioncall> ::= <prefixexp> ':' <Name> <args>

<args> ::= '(' <optional explist> ')'
<args> ::= <tableconstructor>
<args> ::= <String>

<function> ::= <keyword function> <funcbody>

<funcbody> ::= '(' <optional parlist> ')' <block> <keyword end>

<optional parlist> ::= <namelist>
<optional parlist> ::= <namelist> ',' '...'
<optional parlist> ::= '...'
<optional parlist> ::=

# A lone comma is not allowed in an empty fieldlist,
# apparently. This is why I use a dedicated rule
# for an empty table and a '+' sequence,
# instead of a '*' sequence.

<tableconstructor> ::= '{' '}'
<tableconstructor> ::= '{' <fieldlist> '}'

<fieldlist> ::= <field>+ separator => [,;]

<field> ::= '[' <exp> ']' '=' <exp>
<field> ::= <Name> '=' <exp>
<field> ::= <exp>

<keyword and> ~ 'and'
<keyword break> ~ 'break'
<keyword do> ~ 'do'
<keyword else> ~ 'else'
<keyword elseif> ~ 'elseif'
<keyword end> ~ 'end'
<keyword false> ~ 'false'
<keyword for> ~ 'for'
<keyword function> ~ 'function'
<keyword if> ~ 'if'
<keyword in> ~ 'in'
<keyword local> ~ 'local'
<keyword nil> ~ 'nil'
<keyword not> ~ 'not'
<keyword or> ~ 'or'
<keyword repeat> ~ 'repeat'
<keyword return> ~ 'return'
<keyword then> ~ 'then'
<keyword true> ~ 'true'
<keyword until> ~ 'until'
<keyword while> ~ 'while'

# multiline comments are discarded.  The lexer only looks for
# their beginning, and uses an event to throw away the rest
# of the comment

:discard ~ <singleline comment> event => 'singleline comment'

<singleline comment> ~ <singleline comment start>
<singleline comment start> ~ '--'

:discard ~ <multiline comment> event => 'multiline comment'

<multiline comment> ~ '--[' <optional equal signs> '['

<optional equal signs> ~ [=]*

:discard ~ whitespace

# Lua whitespace is locale dependant and so
# is Perl's, hopefully in the same way.
# Anyway, it will be close enough for the moment.

whitespace ~ [\s]+

# Good practice is to *not* use locale extensions for identifiers,
# and we enforce that, so all letters must be a-z or A-Z

<Name> ~ <identifier start char> <optional identifier chars>

:lexeme ~ Name pause => before event => 'Name'

<identifier start char> ~ [a-zA-Z_]

<optional identifier chars> ~ <identifier char>*

<identifier char> ~ [a-zA-Z0-9_]

<String> ::= <single quoted string>

<single quoted string> ~ ['] <optional single quoted chars> [']

<optional single quoted chars> ~ <single quoted char>*

# anything other than vertical space or a single quote

<single quoted char> ~ [^\v'\x5c] # Extra ' for syntax hiliter in UltraEdit (uex).
<single quoted char> ~ '\' [\d\D] # Also an escaped char. Another ' for uex.

<String> ::= <double quoted string>

<double quoted string> ~ ["] <optional double quoted chars> ["]

<optional double quoted chars> ~ <double quoted char>*

# anything other than vertical space or a double quote

<double quoted char> ~ [^\v"\x5c] # Extra " for uex.
<double quoted char> ~ '\' [\d\D] # also an escaped char. Another ' for uex.

<String> ::= <multiline string>

:lexeme ~ <multiline string> pause => before event => 'multiline string'

<multiline string> ~ '[' <optional equal signs> '['

<Number> ~ <hex number>
<Number> ~ <C90 strtod decimal>
<Number> ~ <C90 strtol hex>

<hex number> ~ '0x' <hex digit> <hex digit>
<hex digit> ~ [0-9a-fA-F]

# Numeric representation in Lua is also not an
# exact science -- it is farmed out to the
# implementation's strtod() (for decimal)
# or strtoul() (for hex, if strtod failed).
# This is an attempt at the C90-conformant subset.

<C90 strtod decimal> ~ <optional sign> <decimal digits> <optional exponent>
<C90 strtod decimal> ~ <optional sign> <decimal digits> '.' <optional exponent>
<C90 strtod decimal> ~ <optional sign> '.' <decimal digits> <optional exponent>
<C90 strtod decimal> ~
    <optional sign> <decimal digits> '.' <decimal digits> <optional exponent>

<optional exponent> ~
<optional exponent> ~ [eE] <optional sign> <decimal digits>
<optional sign> ~
<optional sign> ~ [-+]

<C90 strtol hex> ~ [0] [xX] <hex digits>

<decimal digits> ~ [0-9]+

<hex digits> ~ [a-fA-F0-9]+
