package Language::FormulaEngine::Parser;
use Moo;
use Carp;
use Try::Tiny;
use List::Util qw( min max );
use Language::FormulaEngine::Parser::ContextUtil
	qw( calc_text_coordinates format_context_string format_context_multiline );
use namespace::clean;

# ABSTRACT: Create parse tree from an input string
our $VERSION = '0.08'; # VERSION


has parse_tree   => ( is => 'rw' );
has error        => ( is => 'rw' );
has functions    => ( is => 'rw' );
has symbols      => ( is => 'rw' );

sub parse {
	my ($self, $input)= @_;
	$self->reset;
	$self->{input}= $input;
	pos( $self->{input} )= 0;
	try {
		$self->next_token;
		my $tree= $self->parse_expr;
		# It is an error if there was un-processed input.
		$self->token_type eq '0'
			or die sprintf('Unexpected %s "%s" near %s',
				$self->token_type, $self->token_value, $self->token_context);
		$self->parse_tree($tree);
	} catch {
		chomp;
		$self->error($_);
	};
	return $self->parse_tree;
}

sub reset {
	my $self= shift;
	$self->parse_tree(undef);
	$self->error(undef);
	$self->functions({});
	$self->symbols({});
	delete @{$self}{'input','token_type','token_value','token_pos'};
	$self;
}


sub deparse {
	my ($self, $node)= @_;
	$node= $self->parse_tree unless @_ > 1;
	$node->deparse($self);
}


sub input              { shift->{input} }
sub input_pos          { pos( shift->{input} ) }
sub token_type         { shift->{token_type} }
sub token_value        { shift->{token_value} }
sub token_pos          { shift->{token_pos} }


sub next_token {
	my $self= shift;
	
	# If already reached end of input, throw an exception.
	die "Can't call next_token after end of input"
		if '0' eq ($self->{token_type}||'');
	
	# Detect the next token
	my ($type, $val, $pos0, $pos1)= ('','');
	while ($type eq '') {
		$pos0= pos($self->{input}) || 0;
		($type, $val)= $self->scan_token;
		$pos1= pos($self->{input}) || 0;
		# Check for end of buffer, even if it matched.
		if ($pos1 >= length $self->{input}) {
			#pos($self->{input})= $pos0; # rewind to start of token before growing buffer
			#if ($self->_grow_buffer) {
			#	$log->trace("grow buffer succeeded");
			#	$type= '';
			#	next;
			#}
			#pos($self->{input})= $pos1; # restore actual position\
			# If we didn't get a token or are ignoring this final token, then return the EOF token
			if (!defined $type || $type eq '') {
				$type= 0;
				$val= '';
				$pos0= $pos1;
				last;
			}
		}
		defined $type
			or die "Unknown syntax at ".$self->token_context."\n";
		$pos1 > $pos0
			or croak "Tokenizer consumed zero characters";
	}
	@{$self}{'token_type','token_value','token_pos'}= ($type,$val,$pos0);
	return $type, $val;
}


sub consume_token {
	my $self= shift;
	croak "Can't consume EOF"
		if $self->{token_type} eq '0';
	my $val= $self->{token_value};
	$self->next_token;
	return $val;
}

sub token_context {
	my ($self, %args)= @_;
	return format_context_multiline($self->{input}, $self->{token_pos}||0, pos($self->{input})||0, \%args)
		if delete $args{multiline};
	return format_context_string($self->{input}, $self->{token_pos}||0, pos($self->{input})||0);
}


sub parse_expr { shift->parse_or_expr; }

sub parse_or_expr {
	my $self= shift;
	my $first= $self->parse_and_expr;
	return $first unless $self->{token_type} eq 'or';
	my @or_expr= $first;
	while ($self->{token_type} eq 'or') {
		$self->next_token;
		push @or_expr, $self->parse_and_expr;
	}
	return $self->new_call('or', \@or_expr);
}

sub parse_and_expr {
	my $self= shift;
	my $first= $self->parse_not_expr;
	return $first unless $self->{token_type} eq 'and';
	my @and_expr= $first;
	while ($self->{token_type} eq 'and') {
		$self->next_token;
		push @and_expr, $self->parse_not_expr;
	}
	return $self->new_call('and', \@and_expr);
}

sub parse_not_expr {
	my $self= shift;
	if ($self->{token_type} eq 'not' or $self->{token_type} eq '!') {
		$self->next_token;
		return $self->new_call('not', [ $self->parse_cmp_expr ]);
	}
	return $self->parse_cmp_expr;
}

my %_cmp_ops= map { $_ => 1 } qw( > < >= <= != == );
sub parse_cmp_expr {
	my $self= shift;
	my $first= $self->parse_sum_expr;
	return $first unless $_cmp_ops{$self->{token_type}};
	my @expr= $first;
	while ($_cmp_ops{$self->{token_type}}) {
		push @expr, $self->new_string($self->{token_type});
		$self->next_token;
		push @expr, $self->parse_sum_expr;
	}
	return $self->new_call('compare', \@expr);
}

sub parse_sum_expr {
	my $self= shift;
	my $first= $self->parse_prod_expr;
	return $first unless $self->{token_type} eq '+' or $self->{token_type} eq '-';
	my @sum_expr= $first;
	while ($self->{token_type} eq '+' or $self->{token_type} eq '-') {
		my $negate= $self->consume_token eq '-';
		my $operand= $self->parse_prod_expr;
		push @sum_expr, $negate? $self->get_negative($operand) : $operand;
	}
	return $self->new_call('sum', \@sum_expr);
}

sub parse_prod_expr {
	my $self= shift;
	my $value= $self->parse_unit_expr;
	while ($self->{token_type} eq '*' or $self->{token_type} eq '/') {
		my $op= $self->consume_token;
		my $right= $self->parse_unit_expr;
		$value= $self->new_call( $op eq '*'? 'mul' : 'div', [ $value, $right ] );
	}
	return $value;
}

sub parse_unit_expr {
	my $self= shift;
	my $negate= 0;
	my $expr;

	if ($self->{token_type} eq '-') {
		$self->next_token;
		return $self->get_negative($self->parse_unit_expr);
	}

	if ($self->{token_type} eq '(') {
		$self->next_token;
		my $args= $self->parse_list;
		die "Expected ')' near ".$self->token_context."\n"
			if $self->{token_type} ne ')';
		$self->next_token;
		return @$args > 1? $self->new_call('list', $args) : $args->[0];
	}
	
	if ($self->{token_type} eq 'Number') {
		return $self->new_number($self->consume_token);
	}
	
	if ($self->{token_type} eq 'String') {
		return $self->new_string($self->consume_token);
	}
	
	if ($self->{token_type} eq 'Identifier') {
		my $id= $self->consume_token;
		if ($self->{token_type} eq '(') {
			$self->next_token;
			my $args= $self->{token_type} eq ')'? [] : $self->parse_list;
			die "Expected ')' near ".$self->token_context."\n"
				if $self->{token_type} ne ')';
			$self->next_token;
			return $self->new_call($id, $args);
		}
		else {
			return $self->new_symbol($id);
		}
	}
	
	if ($self->{token_type} eq '0') {
		die "Expected expression, but reached end of input\n";
	}
	
	die "Unexpected token $self->{token_type} '$self->{token_value}' near ".$self->token_context."\n";
}

sub parse_list {
	my $self= shift;
	my @args= $self->parse_expr;
	while ($self->{token_type} eq ',') {
		$self->next_token;
		push @args, $self->parse_expr;
	}
	return \@args;
}


sub cmp_operators { qw(  =  ==  !=  <>  >  >=  <  <=  ), "\x{2260}", "\x{2264}", "\x{2265}" }
sub math_operators { qw(  +  -  *  /  ) }
sub logic_operators { qw(  and  or  not  !  ) }
sub list_operators { ',', '(', ')' }
sub keyword_map {
	return {
		(map { $_ => $_ } cmp_operators, math_operators, logic_operators, list_operators),
		'=' => '==', '<>' => '!=', "\x{2260}" => '!=',
		"\x{2264}" => '<=', "\x{2265}" => '>='
	}
}
sub scanner_rules {
	my $self= shift;
	my $keywords= $self->keyword_map;
	my $kw_regex= join '|', map "\Q$_\E",
		sort { length($b) <=> length($a) } # longest keywords get priority
		keys %$keywords;
	
	# Perl 5.20.1 and 5.20.2 have a bug where regex comparisons on unicode strings can crash.
	# It seems to damage the scalar $1, but copying it first fixes the problem.
	my $kw_canonical= $] >= 5.020000 && $] < 5.020003? '$keywords->{lc(my $clone1= $1)}' : '$keywords->{lc $1}';
	return (
		# Pattern Name, Pattern, Token Type and Token Value
		[ 'Whitespace',  qr/(\s+)/, '"" => ""' ], # empty string causes next_token to loop
		[ 'Decimal',     qr/([0-9]*\.?[0-9]+(?:[eE][+-]?[0-9]+)?)\b/, 'Number => $1+0' ],
		[ 'Hexadecimal', qr/0x([0-9A-Fa-f]+)/, 'Number => hex($1)' ],
		[ 'Keywords',    qr/($kw_regex)/, $kw_canonical.' => $1', { keywords => $keywords } ],
		[ 'Identifiers', qr/([A-Za-z_][A-Za-z0-9_.]*)\b/, 'Identifier => $1' ],
		# Single or double quoted string, using Pascal-style repeated quotes for escaping
		[ 'StringLiteral', qr/(?:"((?:[^"]|"")*)"|'((?:[^']|'')*)')/, q%
			do{
				my $str= defined $1? $1 : $2;
				$str =~ s/""/"/g if defined $1;
				$str =~ s/''/'/g if defined $2;
				(String => $str)
			}
		%],
	);
}

sub _build_scan_token_method_body {
	my ($self, $rules)= @_;
	return join('', map
			'  return ' . $_->[2] . ' if $self->{input} =~ /\G' . $_->[1] . "/gc;\n",
			@$rules
		).'  return;' # return empty list of no rule matched
}

sub _build_scan_token_method {
	my ($pkg, $method_name)= @_;
	$pkg= ref $pkg if ref $pkg;
	$method_name= 'scan_token' unless defined $method_name;
	my @rules= $pkg->scanner_rules;
	# collect variables which should be available to the code
	my %vars= map { $_->[3]? %{ $_->[3] } : () } @rules;
	my $code= join "\n",
		(map 'my $'.$_.' = $vars{'.$_.'};', keys %vars),
	    "sub ${pkg}::$method_name {",
		'  my $self= shift;',
		$pkg->_build_scan_token_method_body(\@rules),
		"}\n";
	# closure needed for 5.8 and 5.10 which complain about using a lexical
	# in a sub declared at package scope.
	no warnings 'redefine','closure';
	eval "$code; 1" or die $@ . " for generated scanner code:\n".$code;
	return $pkg->can('scan_token');
}

sub scan_token { my $m= $_[0]->_build_scan_token_method; goto $m; };


sub Language::FormulaEngine::Parser::Node::Call::new {
	my ($class, $name, $params)= @_;
	bless [ $name, $params ], $class;
}
sub Language::FormulaEngine::Parser::Node::Call::is_constant { 0 }
sub Language::FormulaEngine::Parser::Node::Call::function_name { $_[0][0] }
sub Language::FormulaEngine::Parser::Node::Call::parameters { $_[0][1] }
sub Language::FormulaEngine::Parser::Node::Call::evaluate {
	my ($self, $namespace)= @_;
	$namespace->evaluate_call($self);
}
sub Language::FormulaEngine::Parser::Node::Call::simplify {
	my ($node, $namespace)= @_;
	$namespace->simplify_call($node)
}
sub Language::FormulaEngine::Parser::Node::Call::deparse {
	my ($node, $parser)= @_;
	return $node->function_name . (
		!@{$node->parameters}? '()'
		: '( ' .join(', ', map $parser->deparse($_), @{$node->parameters}). ' )'
	)
}

sub new_call {
	my ($self, $fn, $params)= @_;
	$self->functions->{$fn}++; # record dependency on this function
	bless [ $fn, $params ], 'Language::FormulaEngine::Parser::Node::Call';
}


sub Language::FormulaEngine::Parser::Node::symbol::new {
	my ($class, $name)= @_;
	bless \$name, $class;
}

sub Language::FormulaEngine::Parser::Node::Symbol::is_constant { 0 }
sub Language::FormulaEngine::Parser::Node::Symbol::symbol_name { ${$_[0]} }
sub Language::FormulaEngine::Parser::Node::Symbol::evaluate {
	my ($self, $namespace)= @_;
	$namespace->get_value($$self);
}
sub Language::FormulaEngine::Parser::Node::Symbol::simplify {
	my ($self, $namespace)= @_;
	return $namespace->simplify_symref($self);
}
sub Language::FormulaEngine::Parser::Node::Symbol::deparse {
	shift->symbol_name;
}

sub new_symbol  {
	my ($self, $name)= @_;
	$self->symbols->{$name}++; # record dependency on this variable
	bless \$name, 'Language::FormulaEngine::Parser::Node::Symbol';
}


sub Language::FormulaEngine::Parser::Node::String::new {
	my ($class, $value)= @_;
	bless \$value, $class;
}

sub Language::FormulaEngine::Parser::Node::String::is_constant { 1 }
sub Language::FormulaEngine::Parser::Node::String::string_value { ${$_[0]} }
sub Language::FormulaEngine::Parser::Node::String::evaluate { ${$_[0]} }
sub Language::FormulaEngine::Parser::Node::String::simplify { $_[0] }
sub _str_escape {
	my $str= shift;
	$str =~ s/'/''/g;
	"'$str'";
}
sub Language::FormulaEngine::Parser::Node::String::deparse {
	_str_escape(shift->string_value);
}

sub new_string {
	my ($self, $text)= @_;
	bless \$text, 'Language::FormulaEngine::Parser::Node::String'
}


sub Language::FormulaEngine::Parser::Node::Number::new {
	my ($class, $value)= @_;
	$value= 0+$value;
	bless \$value, $class;
}
	
sub Language::FormulaEngine::Parser::Node::Number::is_constant { 1 }
sub Language::FormulaEngine::Parser::Node::Number::number_value { ${$_[0]} }
sub Language::FormulaEngine::Parser::Node::Number::evaluate { ${$_[0]} }
sub Language::FormulaEngine::Parser::Node::Number::simplify { $_[0] }
sub Language::FormulaEngine::Parser::Node::Number::deparse { shift->number_value }

sub new_number {
	my $value= $_[1]+0;
	bless \$value, 'Language::FormulaEngine::Parser::Node::Number'
}


sub get_negative {
	my ($self, $node)= @_;
	return $self->new_number(-$node->number_value) if $node->can('number_value');
	return $node->parameters->[0] if $node->can('function_name') and $node->function_name eq 'negative';
	return $self->new_call('negative', [$node]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::FormulaEngine::Parser - Create parse tree from an input string

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  my $parse_tree= Language::FormulaEngine::Parser->new->parse($string);

=head1 DESCRIPTION

This class scans tokens from an input string and builds a parse tree.  In compiler terminology,
it is both a Scanner and Parser.  It performs a top-down recursive descent parse, because this
is easy and gives good error messages.  It only parses strings, but leaves room for subclasses
to implement streaming.  By default, the parser simply applies a Grammar to the input, without
checking whether the functions or variables exist, but can be subclassed to do more detailed
analysis during the parse.

The generated parse tree is made up of Function nodes (each infix operator is converted to a
named function) and each Function node may contain Symbols, Strings, Numbers, and other
Function nodes.  The parse tree can be passed to the Evaluator for instant execution, or passed
to the Compiler to generate an optimized perl coderef.  The parse tree is lightweight, and does
not include token/context information; this could also be added by a subclass.

=head1 PUBLIC API

=head2 parse

Parse a new input text, updating all derived attributes with the result of the operation.
It returns the value of L</parse_tree> (which is undef if the parse failed).
On failure, the exception is stored in L</error> and other attributes like L</token_pos> may
contain useful diagnostic information.

=head2 parse_tree

This holds the generated parse tree, or C<undef> if the parse failed.  See L</"Parse Nodes">.

=head2 error

This is C<undef> if the parse succeeded, else an error message describing the syntax that ended
the parse.

=head2 functions

A set (hashref) of all function names encountered during the parse.

=head2 symbols

A set (hashref) of all non-function symbols encountered.  (variables, constnts, etc.)

=head2 reset

Clear the results of the previous parse, to re-use the object.  Returns C<$self> for chaining.

=head2 deparse

  my $formula_text= $parser->deparse($tree);

Return a canonical formula text for the parse tree, or a parse tree that you supply.

=head1 EXTENSIBLE API

These methods and attributes are documented for purposes of subclassing the parser.

=head2 input

The input string being scanned.
Code within the parser should access this as C<< $self->{input} >> for efficiency.

=head2 input_pos

Shortcut for C<< pos($self->{input}) >>.

=head2 token_type

Type of current token scanned from C<input>.
Code within the parser should access this as C<< $self->{token_type} >> for efficiency.

=head2 token_value

Value of current token scanned from C<input>, with escape sequences and etc resolved to a
sensible perl value.
Code within the parser should access this as C<< $self->{token_value} >> for efficiency.

=head2 token_pos

An offset within C<input> where this token started.
Code within the parser should access this as C<< $self->{token_pos} >> for efficiency.

=head2 next_token

Advance to the next token, replacing the values of C<token_> variables and updating
C<input_pos>.  Returns the token_type, of which all are true except EOF which has a
type of C<0>, so this also means the function returns true if it parsed a token and
false if it reached EOF.  It dies if no token could be parsed.
If you call next_token again after the eof token, it throws an exception.

This method is a wrapper around L</scan_token>. Override that method to add new token types.

=head2 scan_token

Pattern-match the next token, and either return C<< $type => $value >> or an empty list if
the syntax is invalid.  This is intended to be overridden by subclasses.

=head2 consume_token

  return $self->consume_token if $self->{token_type} eq $desired_type;

This is a shorthand for returning the current C<token_value> while also calling C<next_token>.

=head2 token_context

  my $text= $self->token_context(%options);

Default behavior generates a string like:

  "'blah blah' on line 15, char 12"

Passing C<< token_context(multiline => 1) >> generates a string like

  "Expected something else at line 15, char 16\n" .
  "blah blah blah token blah blah\n" .
  "               ^^^^^\n"

Multiline additionally takes arguments as described in
L<Language::FormulaEngine::Parser::ContextUtil/format_context_multiline>.

=head1 GRAMMAR

=head2 Parse Rules

The default grammar implements the following rules:

  expr      ::= or_expr
  or_expr   ::= and_expr ( 'or' and_expr )*
  and_expr  ::= not_expr ( 'and' not_expr )*
  not_expr  ::= ( 'not' | '!' ) cmp_expr | cmp_expr
  cmp_expr  ::= sum_expr ( ( '=' | '==' | '<>' | '\u2260' | '<' | '<=' | '>' | '>=' ) sum_expr )*
  sum_expr  ::= prod_expr ( ('+' | '-') prod_expr )*
  prod_expr ::= ( unit_expr ('*' | '/') )* unit_expr
  unit_expr ::= '-' unit_expr | Identifier '(' list ')' | '(' (expr|list) ')' | Identifier | Number | String
  list      ::= expr ( ',' expr )* ','?

C<ident>, C<num>, C<str>, and all the punctuation symbols are tokens.

The parser uses a Recursive Descent algorithm implemented as the following method calls.
Each method consumes tokens from C<< $self >> and return a L</"PARSE NODES">:

=over

=item parse_expr

=item parse_or_expr

=item parse_and_expr

=item parse_not_expr

=item parse_cmp_expr

=item parse_sum_expr

=item parse_prod_expr

=item parse_unit_expr

=item parse_list

=back

=head2 Token Types

=over

=item C<'Number'>

All the common decimal representations of integers and floating point numbers
which perl can parse.  Optional decimals and decimal point followed by decimals
and optional exponent, ending at either the end of the input or a non-alphanumeric.

=item C<'String'>

A single-quoted or double-quoted string, treating a double occurrence of the quote
character to mean a literal quote character.  ("Pascal style")

  'apostrophes are''nt hard'

There are no escape sequences though, so to get control characters or awkward unicode
into a string you need something like:

  concat("smile ",char(0x263A))

which depends on those functions being available in the namespace.

=item Keywords...

Keywords include the "word" tokens like 'OR', but also every text literal seen in a parse rule
such as operators and punctuation.
The C<token_type> of the keyword is the canonical version of the keyword, and the C<token_value>
is the actual text that was captured.  The pattern matches the longest keyword possible.

=item C<'Identifier'>

Any alpha (or underscore) followed by any run of alphanumerics,
(including underscore and period).

=back

=head2 Customizing the Token Scanner

The tokens are parsed using a series of regex tests.  The regexes and the code that handles a
match of that regex are found in package attribute L</scanner_rules>.  These regexes and code
fragments get lazily compiled into a package method on the first use (per package).
Meanwhile, several of those regex are built from other package attributes.

=over

=item scanner_rules

This package method returns a list (not arrayref) of ordered elements of the form
C<< [ $name, $regex, $code_fragment, \%vars ] >>.  You can subclass this method to inspect
the rules (probably based on C<$name>) and replace the regexes, or alter the handler code,
or add/remove your own rules.  The regexes are attempted in the order they appear in this
list.  You do not need to use "\G" or "/gc" on these regexes because those are added
automatically during compilation.

=item keyword_map

This package method returns a hashref of all known keywords, mapped to their canonical form.
So for instance, a key of C<< '<>' >> with a value of C<< '!=' >>.  These tokens automatically
become the scanner rule named C<Keywords>.  In turn, the contents of this hashref include
the L</cmp_operators>, L</math_operators>, L</logic_operators>, and L</list_operators> which
can be overridden separately.

This method is called once during the compilation of L</scan_token>, and the result is then
made into a constant and referenced by the compiled method, so dynamic changes to the output
of this method will be ignored.

=item cmp_operators

Package method that returns a list of comparison operators, like '<', '>=', etc.

=item math_operators

Package method that returns a list of math operators, like '*', '+', etc.

=item logic_operators

Package method that returns a list of keywords like 'and', 'or', etc.

=item list_operators

Package method that returns a list of '(', ')', ','

=back

=head2 Parse Nodes

The parse tree takes a minimalist approach to node classification.  In this default
implementation, number values, string values, and symbolic references have just a simple
wrapper around the value, and function calls are just a pair of function name and list of
arguments.  All language operators are represented as function calls.

A blessed node only needs to support one method: C<< ->evaluate($namespace) >>.

The class name of the blessed nodes should be ignored.  A function is anything which
C<< can("function_name") >>, a string is anything which C<< can("string_value") >>, a number is
anything which C<< can("number_value") >> and a symbolic reference is anything which
C<< can("symbolic_name") >>.

Subclasses of Parser should implemnt new node types as needed.  You probable also need to
update L</deparse>.

The parser rules (C<parse_X_expr> methods) create nodes by the following methods on the Parser
class, so that you can easily subclass C<Parser> and override which class of node is getting
created.

=over

=item new_call

  $node= $parser->new_call( $function_name, $parameters );

Generate a node for a function call.  The returned node has attributes C<function_name>
and C<parameters>

=item new_symbol

  $node= $parser->new_symbol($symbol_name);

A reference to a symbolic value (i.e. variable or constant).
It has one attribute C<symbol_name>.

=item new_string

  $node= $parser->new_string($string_value);

A string literal.  It has an attribute C<string_value> holding the raw value.

=item new_number

  $plain_scalar= $parser->new_number($value);

A numeric constant.  It has an attribute C<number_value> holding the raw value.

=item get_negative

  $negative_node= $parser->get_negative( $node );

Utility method to get the "opposite of" a parse node.  By default, this wraps it with the
function C<'negative'>, unless it already was that function then it unwraps the parameter.
It performs simple negation on numbers.

=back

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad, IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
