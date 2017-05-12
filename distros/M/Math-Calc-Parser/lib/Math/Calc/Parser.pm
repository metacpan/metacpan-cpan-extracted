package Math::Calc::Parser;
use strict;
use warnings;
use Carp 'croak';
use Exporter ();
use List::Util 'reduce';
use Math::Complex;
use POSIX qw/ceil floor/;
use Scalar::Util qw/blessed looks_like_number/;

our $VERSION = '1.001';
our @ISA = 'Exporter';
our @EXPORT_OK = 'calc';
our $ERROR;

# See disclaimer in Math::Round
use constant ROUND_HALF => 0.50000000000008;

{
	my %operators = (
		'<<' => { assoc => 'left' },
		'>>' => { assoc => 'left' },
		'+'  => { assoc => 'left' },
		'-'  => { assoc => 'left' },
		'*'  => { assoc => 'left' },
		'/'  => { assoc => 'left' },
		'%'  => { assoc => 'left' },
		'^'  => { assoc => 'right' },
		'!'  => { assoc => 'left' },
		# Dummy operators for unary minus/plus
		'u-' => { assoc => 'right' },
		'u+' => { assoc => 'right' },
	);
	
	# Ordered lowest precedence to highest
	my @op_precedence = (
		['<<','>>'],
		['+','-'],
		['*','/','%'],
		['u-','u+'],
		['^'],
		['!'],
	);
	
	# Cache operator precedence
	my (%lower_prec, %higher_prec);
	$higher_prec{$_} = 1 for keys %operators;
	foreach my $set (@op_precedence) {
		delete @higher_prec{@$set};
		foreach my $op (@$set) {
			$operators{$op}{equal_to}{$_} = 1 for @$set;
			$operators{$op}{lower_than}{$_} = 1 for keys %higher_prec;
			$operators{$op}{higher_than}{$_} = 1 for keys %lower_prec;
		}
		$lower_prec{$_} = 1 for @$set;
	}
	
	sub _operator { $operators{shift()} }
}

{
	sub _real { blessed $_[0] ? $_[0]->Re : $_[0] }
	sub _each { blessed $_[0] ? cplx($_[1]->($_[0]->Re), $_[1]->($_[0]->Im)) : $_[1]->($_[0]) }
	
	# Adapted from Math::Round
	sub _round { $_[0] >= 0 ? floor($_[0] + ROUND_HALF) : ceil($_[0] - ROUND_HALF) }
	
	my %functions = (
		'<<'  => { args => 2, code => sub { _real($_[0]) << _real($_[1]) } },
		'>>'  => { args => 2, code => sub { _real($_[0]) >> _real($_[1]) } },
		'+'   => { args => 2, code => sub { $_[0] + $_[1] } },
		'-'   => { args => 2, code => sub { $_[0] - $_[1] } },
		'*'   => { args => 2, code => sub { $_[0] * $_[1] } },
		'/'   => { args => 2, code => sub { $_[0] / $_[1] } },
		'%'   => { args => 2, code => sub { _real($_[0]) % _real($_[1]) } },
		'^'   => { args => 2, code => sub { $_[0] ** $_[1] } },
		'!'   => { args => 1, code => sub { die 'Factorial of negative number' if _real($_[0]) < 0;
		                                    die 'Factorial of infinity' if _real($_[0]) == 'inf';
		                                    reduce { $a * $b } 1, 1.._real($_[0]) } },
		'u-'  => { args => 1, code => sub { -$_[0] } },
		'u+'  => { args => 1, code => sub { +$_[0] } },
		sqrt  => { args => 1, code => sub { sqrt $_[0] } },
		pi    => { args => 0, code => sub { pi } },
		i     => { args => 0, code => sub { i } },
		e     => { args => 0, code => sub { exp 1 } },
		ln    => { args => 1, code => sub { log $_[0] } },
		log   => { args => 1, code => sub { log($_[0])/log(10) } },
		logn  => { args => 2, code => sub { log($_[0])/log($_[1]) } },
		sin   => { args => 1, code => sub { sin $_[0] } },
		cos   => { args => 1, code => sub { cos $_[0] } },
		tan   => { args => 1, code => sub { tan $_[0] } },
		asin  => { args => 1, code => sub { asin $_[0] } },
		acos  => { args => 1, code => sub { acos $_[0] } },
		atan  => { args => 1, code => sub { atan $_[0] } },
		abs   => { args => 1, code => sub { abs $_[0] } },
		rand  => { args => 0, code => sub { rand } },
		int   => { args => 1, code => sub { _each($_[0], sub { int $_[0] }) } },
		floor => { args => 1, code => sub { _each($_[0], sub { floor $_[0] }) } },
		ceil  => { args => 1, code => sub { _each($_[0], sub { ceil $_[0] }) } },
		round => { args => 1, code => sub { _each($_[0], sub { _round $_[0] }) } },
	);
	
	sub _default_functions { +{%functions} }
}

{
	my $singleton;
	sub _instance { blessed $_[0] ? $_[0] : ($singleton ||= $_[0]->new) }
}

sub calc ($) { _instance(__PACKAGE__)->evaluate($_[0]) }

sub new { bless {}, shift }

sub error { _instance(shift)->{error} }

sub _functions { shift->{_functions} ||= _default_functions() }

sub add_functions {
	my ($self, %functions) = @_;
	foreach my $name (keys %functions) {
		croak qq{Function "$name" has invalid name} unless $name =~ m/\A[a-z]\w*\z/i;
		my $definition = $functions{$name};
		$definition = { args => 0, code => $definition } if ref $definition eq 'CODE';
		croak qq{No argument count for function "$name"}
			unless defined (my $args = $definition->{args});
		croak qq{Invalid argument count for function "$name"}
			unless $args =~ m/\A\d+\z/ and $args >= 0;
		croak qq{No coderef for function "$name"}
			unless defined (my $code = $definition->{code});
		croak qq{Invalid coderef for function "$name"} unless ref $code eq 'CODE';
		$self->_functions->{$name} = { args => $args, code => $code };
	}
	return $self;
}

sub remove_functions {
	my ($self, @functions) = @_;
	foreach my $name (@functions) {
		next unless defined $name;
		next if defined _operator($name); # Do not remove operator functions
		delete $self->_functions->{$name};
	}
	return $self;
}

my $token_re = qr{(
	( 0x[0-9a-f]+ | 0b[01]+ | 0[0-7]+ )          # Octal/hex/binary numbers
	| (?: [0-9]*\. )? [0-9]+ (?: e[-+]?[0-9]+ )? # Decimal numbers
	| [(),]                                      # Parentheses and commas
	| \w+                                        # Functions
	| (?: [-+*/^%!] | << | >> )                  # Operators
	| [^\s\w(),.\-+*/^%!<>]+                     # Unknown tokens (but skip whitespace)
)}ix;

sub parse {
	my ($self, $expr) = @_;
	$self = _instance($self);
	my (@expr_queue, @oper_stack, $binop_possible);
	while ($expr =~ /$token_re/g) {
		my ($token, $octal) = ($1, $2);
		
		# Octal/hex/binary numbers
		$token = oct $octal if defined $octal and length $octal;
		
		# Implicit multiplication
		if ($binop_possible and $token ne ')' and $token ne ','
		    and !defined _operator($token)) {
			_shunt_operator(\@expr_queue, \@oper_stack, '*');
		}
		
		if (defined _operator($token)) {
			# Detect unary minus/plus
			if (!$binop_possible and ($token eq '-' or $token eq '+')) {
				$token = "u$token";
			}
			_shunt_operator(\@expr_queue, \@oper_stack, $token);
			$binop_possible = $token eq '!' ? 1 : 0;
		} elsif ($token eq '(') {
			_shunt_left_paren(\@expr_queue, \@oper_stack);
			$binop_possible = 0;
		} elsif ($token eq ')') {
			_shunt_right_paren(\@expr_queue, \@oper_stack)
				or die "Mismatched parentheses\n";
			$binop_possible = 1;
		} elsif ($token eq ',') {
			_shunt_comma(\@expr_queue, \@oper_stack)
				or die "Misplaced comma or mismatched parentheses\n";
			$binop_possible = 0;
		} elsif (looks_like_number $token) {
			_shunt_number(\@expr_queue, \@oper_stack, $token);
			$binop_possible = 1;
		} elsif ($token =~ m/\A\w+\z/) {
			die qq{Invalid function "$token"\n} unless exists $self->_functions->{$token};
			if ($self->_functions->{$token}{args} > 0) {
				_shunt_function_with_args(\@expr_queue, \@oper_stack, $token);
				$binop_possible = 0;
			} else {
				_shunt_function_no_args(\@expr_queue, \@oper_stack, $token);
				$binop_possible = 1;
			}
		} else {
			die qq{Unknown token "$token"\n};
		}
	}
	
	# Leftover operators go at the end
	while (@oper_stack) {
		die "Mismatched parentheses\n" if $oper_stack[-1] eq '(';
		push @expr_queue, pop @oper_stack;
	}
	
	return \@expr_queue;
}

sub _shunt_number {
	my ($expr_queue, $oper_stack, $num) = @_;
	push @$expr_queue, $num;
	return 1;
}

sub _shunt_operator {
	my ($expr_queue, $oper_stack, $oper) = @_;
	my $oper_stat = _operator($oper);
	my $assoc = $oper_stat->{assoc};
	while (@$oper_stack and defined _operator(my $top_oper = $oper_stack->[-1])) {
		if ($oper_stat->{lower_than}{$top_oper}
		    or ($assoc eq 'left' and $oper_stat->{equal_to}{$top_oper})) {
			push @$expr_queue, pop @$oper_stack;
		} else {
			last;
		}
	}
	push @$oper_stack, $oper;
	return 1;
}

sub _shunt_function_with_args {
	my ($expr_queue, $oper_stack, $function) = @_;
	push @$oper_stack, $function;
	return 1;
}

sub _shunt_function_no_args {
	my ($expr_queue, $oper_stack, $function) = @_;
	push @$expr_queue, $function;
	return 1;
}

sub _shunt_left_paren {
	my ($expr_queue, $oper_stack) = @_;
	push @$oper_stack, '(';
	return 1;
}

sub _shunt_right_paren {
	my ($expr_queue, $oper_stack) = @_;
	while (@$oper_stack and $oper_stack->[-1] ne '(') {
		push @$expr_queue, pop @$oper_stack;
	}
	return 0 unless @$oper_stack and $oper_stack->[-1] eq '(';
	pop @$oper_stack;
	if (@$oper_stack and $oper_stack->[-1] ne '('
	    and !defined _operator($oper_stack->[-1])) {
		# Not parentheses or operator, must be function
		push @$expr_queue, pop @$oper_stack;
	}
	return 1;
}

sub _shunt_comma {
	my ($expr_queue, $oper_stack) = @_;
	while (@$oper_stack and $oper_stack->[-1] ne '(') {
		push @$expr_queue, pop @$oper_stack;
	}
	return 0 unless @$oper_stack and $oper_stack->[-1] eq '(';
	return 1;
}

sub evaluate {
	my ($self, $expr) = @_;
	$self = _instance($self);
	$expr = $self->parse($expr) unless ref $expr eq 'ARRAY';
	
	die "No expression to evaluate\n" unless @$expr;
	
	my @eval_stack;
	foreach my $token (@$expr) {
		die "Undefined token in evaluate\n" unless defined $token;
		if (exists $self->_functions->{$token}) {
			my $function = $self->_functions->{$token};
			my $num_args = $function->{args};
			die "Malformed expression\n" if @eval_stack < $num_args;
			my @args = $num_args > 0 ? splice @eval_stack, -$num_args : ();
			my ($result, $errored, $error);
			{
				local $@;
				unless (eval { $result = $function->{code}(@args); 1 }) {
					$errored = 1;
					$error = $@;
				}
			}
			if ($errored) {
				$error = '' unless defined $error;
				$error =~ s/ at .+? line \d+\.$//i;
				chomp $error;
				die qq{Error in function "$token": $error\n};
			}
			die qq{Undefined result from function "$token"\n} unless defined $result;
			{
				no warnings 'numeric';
				push @eval_stack, 0+$result;
			}
		} elsif (looks_like_number $token) {
			push @eval_stack, $token;
		} else {
			die qq{Invalid function "$token"\n};
		}
	}
	
	die "Malformed expression\n" if @eval_stack > 1;
	
	return $eval_stack[0];
}

sub try_evaluate {
	my ($self, $expr) = @_;
	$self = _instance($self);
	delete $self->{error};
	undef $ERROR;
	local $@;
	my $result;
	unless (eval { $result = $self->evaluate($expr); 1 }) {
		chomp(my $error = $@);
		$self->{error} = $ERROR = $error;
		return undef;
	}
	return $result;
}

1;

=encoding utf8

=head1 NAME

Math::Calc::Parser - Parse and evaluate mathematical expressions

=head1 SYNOPSIS

  use Math::Calc::Parser 'calc';
  
  my $result = calc '2 + 2'; # 4
  my $result = calc 'int rand 5'; # Random integer between 0 and 4
  my $result = calc 'sqrt -1'; # i
  my $result = calc '0xff << 2'; # 1020
  my $result = calc '1/0'; # Division by 0 exception
  
  # Class methods
  my $result = Math::Calc::Parser->evaluate('2 + 2'); # 4
  my $result = Math::Calc::Parser->evaluate('3pi^2'); # 29.608813203268
  my $result = Math::Calc::Parser->evaluate('0.7(ln 4)'); # 0.970406052783923
  
  # With more advanced error handling
  my $result = Math::Calc::Parser->try_evaluate('rand(abs'); # undef (Mismatched parentheses)
  if (defined $result) {
    print "Result: $result\n";
  } else {
    print "Error: ".Math::Calc::Parser->error."\n";
  }
  
  # Or as an object for more control
  my $parser = Math::Calc::Parser->new;
  $parser->add_functions(triple => { args => 1, code => sub { $_[0]*3 } });
  $parser->add_functions(pow => { args => 2, code => sub { $_[0] ** $_[1] });
  $parser->add_functions(one => sub { 1 }, two => sub { 2 }, three => sub { 3 });
  
  my $result = $parser->evaluate('2(triple one)'); # 2*(1*3) = 6
  my $result = $parser->evaluate('pow(triple two, three)'); # (2*3)^3 = 216
  my $result = $parser->try_evaluate('triple triple'); # undef (Malformed expression)
  die $parser->error unless defined $result;
  
  $parser->remove_functions('pi', 'e');
  $parser->evaluate('3pi'); # Invalid function exception

=head1 DESCRIPTION

L<Math::Calc::Parser> is a simplified mathematical expression evaluator with
support for complex and trigonometric operations, implicit multiplication, and
perlish "parentheses optional" functions, while being safe for arbitrary user
input. It parses input strings into a structure based on
L<Reverse Polish notation|http://en.wikipedia.org/wiki/Reverse_Polish_notation>
(RPN), and then evaluates the result. The list of recognized functions may be
customized using L</"add_functions"> and L</"remove_functions">.

=head1 FUNCTIONS

=head2 calc

  use Math::Calc::Parser 'calc';
  my $result = calc '2+2';
  
  $ perl -MMath::Calc::Parser=calc -E 'say calc "2+2"'
  $ perl -Math -e '2+2'

Compact exportable function wrapping L</"evaluate"> for string expressions.
Throws an exception on error. See L<ath> for easy compact one-liners.

=head1 METHODS

Aside from C<add_functions> and C<remove_functions>, all methods can be called
as class methods, and will act on a singleton object with the default functions
available.

=head2 new

  my $parser = Math::Calc::Parser->new;

Creates a new L<Math::Calc::Parser> object.

=head2 parse

  my $parsed = Math::Calc::Parser->parse('5 / e^(i*pi)');
  my $parsed = $parser->parse('3pi');

Parses a mathematical expression. On success, returns an array reference
representation of the expression in RPN notation which can be passed to
L</"evaluate">. Throws an exception on failure.

=head2 evaluate

  my $result = Math::Calc::Parser->evaluate($parsed);
  my $result = Math::Calc::Parser->evaluate('log rand 7');
  my $result = $parser->evaluate('round 13/3');

Evaluates a mathematical expression. The argument can be either an arrayref
from L</"parse"> or a string expression which will be passed to L</"parse">.
Returns the result of the expression on success or throws an exception on
failure.

=head2 try_evaluate

  if (defined (my $result = Math::Calc::Parser->evaluate('floor 2.5'))) {
    print "Result: $result\n";
  } else {
    print "Error: ".Math::Calc::Parser->error."\n";
  }
  
  if (defined (my $result = $parser->evaluate('log(5'))) {
  	print "Result: $result\n";
  } else {
  	print "Error: ".$parser->error."\n";
  }

Same as L</"evaluate"> but instead of throwing an exception on failure, returns
undef and sets the L</"error"> attribute to the error message. The error
message for the most recent L</"try_evaluate"> call can also be retrieved from
the package variable C<$Math::Calc::Parser::ERROR>.

=head2 error

  my $result = Math::Calc::Parser->try_evaluate('(i');
  die Math::Calc::Parser->error unless defined $result;
  my $result = $parser->try_evaluate('2//');
  die $parser->error unless defined $result;

Returns the error message after a failed L</"try_evaluate">.

=head2 add_functions

  $parser->add_functions(
    my_function => { args => 5, code => sub { return grep { $_ > 0 } @_; } },
    other_function => sub { 20 }
  );

Adds functions to be recognized by the parser object. Keys are function names
which must start with an alphabetic character and consist only of
L<word characters|http://perldoc.perl.org/perlrecharclass.html#Word-characters>.
Values are either a hashref containing C<args> and C<code> keys, or a coderef
that is assumed to be a 0-argument function. C<args> must be an integer greater
than or equal to C<0>. C<code> or the passed coderef will be called with the
numeric operands passed as parameters, and must either return a numeric result
or throw an exception. Non-numeric results will be cast to numbers in the usual
perl fashion, and undefined results will throw an evaluation error.

=head2 remove_functions

  $parser->remove_functions('rand','nonexistent');

Removes functions from the parser object if they exist. Can be used to remove
default functions as well as functions previously added with
L</"add_functions">.

=head1 OPERATORS

L<Math::Calc::Parser> recognizes the following operators with their usual
mathematical definitions.

  +, -, *, /, %, ^, !, <<, >>

Note: C<+> and C<-> can represent both binary addition/subtraction and unary
negation.

=head1 DEFAULT FUNCTIONS

L<Math::Calc::Parser> parses several functions by default, which can be
customized using L</"add_functions"> or L</"remove_functions"> on an object
instance.

=over

=item abs

Absolute value.

=item acos

=item asin

=item atan

Inverse sine, cosine, and tangent.

=item ceil

Round up to nearest integer.

=item cos

Cosine.

=item e

Euler's number.

=item floor

Round down to nearest integer.

=item i

Imaginary unit.

=item int

Cast (truncate) to integer.

=item ln

Natural log.

=item log

Log base 10.

=item logn

Log with arbitrary base given as second argument.

=item pi

π

=item rand

Random value between 0 and 1 (exclusive of 1).

=item round

Round to nearest integer, with halfway cases rounded away from zero.

=item sin

Sine.

=item sqrt

Square root.

=item tan

Tangent.

=back

=head1 CAVEATS

While parentheses are optional for functions with 0 or 1 argument, they are
required when a comma is used to separate multiple arguments.

Due to the nature of handling complex numbers, the evaluated result may be a
L<Math::Complex> object. These objects can be directly printed or used in
numeric operations but may be more difficult to use in comparisons.

Operators that are not defined to operate on complex numbers will return the
result of the operation on the real components of their operands. This includes
the operators C<E<lt>E<lt>>, C<E<gt>E<gt>>, C<%>, and C<!>.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Math::Complex>
