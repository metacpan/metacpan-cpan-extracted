package Math::Calc::Parser;
use strict;
use warnings;
use utf8;
use Carp ();
use Exporter ();
use Math::Complex ();
use POSIX ();
use Scalar::Util ();

our $VERSION = '1.005';
our @ISA = 'Exporter';
our @EXPORT_OK = 'calc';
our $ERROR;

# See disclaimer in Math::Round
use constant ROUND_HALF => 0.50000000000008;

BEGIN {
	local $@;
	if (eval { require Math::Random::Secure; 1 }) {
		Math::Random::Secure->import('rand');
	}
}

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
	sub _real { Scalar::Util::blessed $_[0] && $_[0]->isa('Math::Complex') ? $_[0]->Re : $_[0] }
	sub _each { Scalar::Util::blessed $_[0] && $_[0]->isa('Math::Complex') ? Math::Complex::cplx($_[1]->($_[0]->Re), $_[1]->($_[0]->Im)) : $_[1]->($_[0]) }
	
	# Adapted from Math::Round
	sub _round { $_[0] >= 0 ? POSIX::floor($_[0] + ROUND_HALF) : POSIX::ceil($_[0] - ROUND_HALF) }
	
	sub _fact_check {
		my $r = _real($_[0]);
		die 'Factorial of negative number' if $r < 0;
		die 'Factorial of infinity' if $r == 'inf';
		die 'Factorial of NaN' if $r != $r;
		return $r;
	}
	
	sub _atan_factor { Math::BigFloat->new(1)->bsub($_[0]->copy->bpow(2))->bsqrt }
	
	my %functions = (
		'<<'  => { args => 2, code => sub { _real($_[0]) << _real($_[1]) } },
		'>>'  => { args => 2, code => sub { _real($_[0]) >> _real($_[1]) } },
		'+'   => { args => 2, code => sub { $_[0] + $_[1] } },
		'-'   => { args => 2, code => sub { $_[0] - $_[1] } },
		'*'   => { args => 2, code => sub { $_[0] * $_[1] } },
		'/'   => { args => 2, code => sub { $_[0] / $_[1] } },
		'%'   => { args => 2, code => sub { _real($_[0]) % _real($_[1]) } },
		'^'   => { args => 2, code => sub { $_[0] ** $_[1] } },
		'!'   => { args => 1,
			code => sub { my $r = _fact_check($_[0]); my ($n, $f) = (2, 1); $f *= $n++ while $f != 'inf' and $n <= $r; $f },
			bignum_code => sub { my $r = _fact_check($_[0]); $r->copy->bfac } },
		'u-'  => { args => 1, code => sub { -$_[0] } },
		'u+'  => { args => 1, code => sub { +$_[0] } },
		sqrt  => { args => 1, code => sub { Math::Complex::sqrt $_[0] }, bignum_code => sub { $_[0]->copy->bsqrt } },
		pi    => { args => 0, code => sub { Math::Complex::pi }, bignum_code => sub { Math::BigFloat->bpi } },
		'π'   => { args => 0, code => sub { Math::Complex::pi }, bignum_code => sub { Math::BigFloat->bpi } },
		i     => { args => 0, code => sub { Math::Complex::i }, bignum_code => sub { Math::BigFloat->bnan } },
		e     => { args => 0, code => sub { exp 1 }, bignum_code => sub { Math::BigFloat->new(1)->bexp } },
		ln    => { args => 1, code => sub { Math::Complex::ln $_[0] }, bignum_code => sub { $_[0]->copy->blog } },
		log   => { args => 1, code => sub { Math::Complex::log10 $_[0] }, bignum_code => sub { $_[0]->copy->blog(10) } },
		logn  => { args => 2, code => sub { Math::Complex::log($_[0]) / Math::Complex::log($_[1]) }, bignum_code => sub { $_[0]->copy->blog($_[1]) } },
		sin   => { args => 1, code => sub { Math::Complex::sin $_[0] }, bignum_code => sub { $_[0]->copy->bsin } },
		cos   => { args => 1, code => sub { Math::Complex::cos $_[0] }, bignum_code => sub { $_[0]->copy->bcos } },
		tan   => { args => 1, code => sub { Math::Complex::tan $_[0] }, bignum_code => sub { scalar $_[0]->copy->bsin->bdiv($_[0]->copy->bcos) } },
		asin  => { args => 1, code => sub { Math::Complex::asin $_[0] }, bignum_code => sub { $_[0]->copy->batan2(_atan_factor($_[0])->badd(1))->bmul(2) } },
		acos  => { args => 1, code => sub { Math::Complex::acos $_[0] }, bignum_code => sub { _atan_factor($_[0])->batan2($_[0]->copy->badd(1))->bmul(2) } },
		atan  => { args => 1, code => sub { Math::Complex::atan $_[0] }, bignum_code => sub { $_[0]->copy->batan } },
		atan2 => { args => 2, code => sub { Math::Complex::atan2 $_[0], $_[1] }, bignum_code => sub { $_[0]->copy->batan2($_[1]) } },
		abs   => { args => 1, code => sub { abs $_[0] } },
		rand  => { args => 0, code => sub { rand }, bignum_code => sub { Math::BigFloat->new(rand) } },
		int   => { args => 1, code => sub { _each($_[0], sub { int $_[0] }) } },
		floor => { args => 1, code => sub { _each($_[0], sub { POSIX::floor $_[0] }) }, bignum_code => sub { $_[0]->copy->bfloor } },
		ceil  => { args => 1, code => sub { _each($_[0], sub { POSIX::ceil $_[0] }) }, bignum_code => sub { $_[0]->copy->bceil } },
		round => { args => 1, code => sub { _each($_[0], sub { _round $_[0] }) }, bignum_code => sub { $_[0]->copy->bfround(0, 'common') },
			# Math::BigRat ->as_float broken with upgrading active
			bigrat_code => sub { local $Math::BigFloat::upgrade = undef; $_[0]->as_float->bfround(0, 'common') } },
	);
	
	sub _default_functions { +{%functions} }
}

{
	my $singleton;
	sub _instance { Scalar::Util::blessed $_[0] ? $_[0] : ($singleton ||= $_[0]->new) }
}

sub calc ($) { _instance(__PACKAGE__)->evaluate($_[0]) }

sub new {
	my $class = shift;
	my %params = @_ == 1 ? %{$_[0]} : @_;
	my $self = bless {}, $class;
	$self->bignum($params{bignum}) if exists $params{bignum};
	$self->bigrat($params{bigrat}) if exists $params{bigrat};
	return $self;
}

sub error { _instance(shift)->{error} }

sub bignum {
	my $self = shift;
	return $self->{bignum} unless @_;
	$self->{bignum} = !!shift;
	if ($self->{bignum}) {
		require Math::BigInt;
		Math::BigInt->VERSION('1.999722');
		require Math::BigFloat;
		Math::BigFloat->VERSION('1.999722');
		Math::BigInt->upgrade('Math::BigFloat');
		Math::BigFloat->downgrade('Math::BigInt');
		Math::BigFloat->upgrade(undef);
	}
	return $self;
}

sub bigrat {
	my $self = shift;
	return $self->{bigrat} unless @_;
	$self->{bigrat} = !!shift;
	if ($self->{bigrat}) {
		require Math::BigInt;
		Math::BigInt->VERSION('1.999722');
		require Math::BigRat;
		Math::BigRat->VERSION('0.260804');
		require Math::BigFloat;
		Math::BigFloat->VERSION('1.999722');
		Math::BigInt->upgrade('Math::BigFloat');
		Math::BigFloat->upgrade('Math::BigRat');
		Math::BigFloat->downgrade(undef);
	}
	return $self;
}

sub _functions { shift->{_functions} ||= _default_functions() }

sub add_functions {
	my ($self, %functions) = @_;
	foreach my $name (keys %functions) {
		Carp::croak qq{Function "$name" has invalid name} unless $name =~ m/\A[a-z]\w*\z/i;
		my $definition = $functions{$name};
		$definition = { args => 0, code => $definition } if ref $definition eq 'CODE';
		Carp::croak qq{No argument count for function "$name"}
			unless defined (my $args = $definition->{args});
		Carp::croak qq{Invalid argument count for function "$name"}
			unless $args =~ m/\A\d+\z/ and $args >= 0;
		Carp::croak qq{No coderef for function "$name"}
			unless defined (my $code = $definition->{code});
		Carp::croak qq{Invalid coderef for function "$name"} unless ref $code eq 'CODE';
		my %function = (args => $args, code => $code);
		$function{bignum_code} = $definition->{bignum_code} if defined $definition->{bignum_code};
		$function{bigrat_code} = $definition->{bigrat_code} if defined $definition->{bigrat_code};
		$self->_functions->{$name} = \%function;
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
	my $bignum = $self->bignum;
	my $bigrat = $self->bigrat;
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
		} elsif (Scalar::Util::looks_like_number $token) {
			$token = Math::BigFloat->new($token) if $bignum or $bigrat;
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
	
	my $bignum = $self->bignum;
	my $bigrat = $self->bigrat;
	my @eval_stack;
	foreach my $token (@$expr) {
		die "Undefined token in evaluate\n" unless defined $token;
		if (exists $self->_functions->{$token}) {
			my $function = $self->_functions->{$token};
			my $num_args = $function->{args};
			die "Malformed expression\n" if @eval_stack < $num_args;
			my @args = $num_args > 0 ? splice @eval_stack, -$num_args : ();
			my $code = $function->{code};
			$code = $function->{bignum_code} if ($bignum or $bigrat) and defined $function->{bignum_code};
			$code = $function->{bigrat_code} if $bigrat and defined $function->{bigrat_code};
			my ($result, $errored, $error);
			{
				local $@;
				unless (eval { $result = $code->(@args); 1 }) {
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
				push @eval_stack, $result+0;
			}
		} elsif (Scalar::Util::looks_like_number $token) {
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
  use utf8; # for π in source code
  
  my $result = calc '2 + 2'; # 4
  my $result = calc 'int rand 5'; # Random integer between 0 and 4
  my $result = calc 'sqrt -1'; # i
  my $result = calc '0xff << 2'; # 1020
  my $result = calc '1/0'; # Division by 0 exception
  
  # Class methods
  my $result = Math::Calc::Parser->evaluate('2 + 2'); # 4
  my $result = Math::Calc::Parser->evaluate('3π^2'); # 29.608813203268
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
  
  $parser->remove_functions('π', 'e');
  $parser->evaluate('3π'); # Invalid function exception
  
  # Arbitrary precision calculations - use only in a controlled environment
  $parser->bignum(1);
  my $result = $parser->evaluate('30!'); # 265252859812191058636308480000000
  my $result = $parser->evaluate('atan pi'); # 1.262627255678911683444322083605698343509
  
  # Rational number calculations - use only in a controlled environment
  $parser->bigrat(1);
  my $result = $parser->evaluate('3 / 9'); # 1/3
  my $result = $parser->evaluate('3 >> 2'); # 3/4

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

=head1 ATTRIBUTES

These attributes can only be set on instantiated objects.

=head2 bignum

  my $bool = $parser->bignum;
  $parser  = $parser->bignum($bool);

Enable support for arbitrary precision numbers using L<Math::BigInt> and
L<Math::BigFloat>. This will avoid losing precision when working with floats or
large integers, but see L</"BIGNUM CAVEATS">.

=head2 bigrat

  my $bool = $parser->bigrat;
  $parser  = $parser->bigrat($bool);

Enable support for precise rational numbers using L<Math::BigRat>. This will
avoid losing precision when working with integer divison and similar
operations, and will result in output like C<3/7> where possible, but see
L</"BIGNUM CAVEATS">.

=head1 METHODS

Aside from C<add_functions> and C<remove_functions>, all methods can be called
as class methods, and will act on a singleton object with the default functions
available.

=head2 new

  my $parser = Math::Calc::Parser->new;
  my $parser = Math::Calc::Parser->new(bignum => 1);

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

  if (defined (my $result = Math::Calc::Parser->try_evaluate('floor 2.5'))) {
    print "Result: $result\n";
  } else {
    print "Error: ".Math::Calc::Parser->error."\n";
  }
  
  if (defined (my $result = $parser->try_evaluate('log(5'))) {
  	print "Result: $result\n";
  } else {
  	print "Error: ".$parser->error."\n";
  }

Same as L</"evaluate"> but instead of throwing an exception on failure, returns
undef. The L</"error"> method can then be used to retrieve the error message.
The error message for the most recent L</"try_evaluate"> call can also be
retrieved from the package variable C<$Math::Calc::Parser::ERROR>.

=head2 error

  my $result = Math::Calc::Parser->try_evaluate('(i');
  die Math::Calc::Parser->error unless defined $result;
  my $result = $parser->try_evaluate('2//');
  die $parser->error unless defined $result;

Returns the error message after a failed L</"try_evaluate">.

=head2 add_functions

  $parser->add_functions(
    my_function => { args => 5, code => sub { return grep { $_ > 0 } @_; } },
    other_function => sub { 20 },
    bignum_function => { args => 1, code => sub { 2 ** $_[0] }, bignum_code => sub { Math::BigInt->new(2)->bpow($_[0]) } },
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

Alternate implementations to be used when L</"bignum"> or L</"bigrat"> is
enabled can be passed as C<bignum_code> and C<bigrat_code> respectively.
C<bignum_code> will also be used for L</"bigrat"> calculations if
C<bigrat_code> is not separately defined; it is not common that these will need
separate implementations.

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

=item atan2

Two-argument inverse tangent of first argument divided by second argument.

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

=item π

π (this must be the decoded Unicode character)

=item rand

Random value between 0 and 1 (exclusive of 1). Uses L<Math::Random::Secure> if
installed.

=item round

Round to nearest integer, with halfway cases rounded away from zero. Due to
bugs in L<Math::BigRat>, precision may be lost with L</"bigrat"> enabled.

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

=head1 BIGNUM CAVEATS

The L<Math::BigInt>, L<Math::BigFloat>, and L<Math::BigRat> packages are useful
for working with numbers without losing precision, and can be used by this
module by setting the L</"bignum"> or L</"bigrat"> attributes, but care should
be taken. They will perform significantly slower than native Perl numbers, and
can result in an operation that does not terminate or one that uses up all your
memory.

Additionally, similar to when using the L<bignum> or L<bigrat> pragmas, the
auto-upgrading and downgrading behavior of these modules can only be set
globally, so enabling these options will affect all other uses of these modules
in your program. For the same reason, it is not recommended to enable both
L</"bignum"> and L</"bigrat"> in the same program.

The evaluated result may be a L<Math::BigInt>, L<Math::BigFloat>,
L<Math::BigRat>, or other similar type of object. These objects can be printed
and behave normally as numbers.

L<Math::BigFloat> defaults to rounding values at 40 digits in division. This
can be controlled by setting the global L<Math::BigFloat/"ACCURACY AND PRECISION">,
but may have a large impact on performance and memory usage.

Complex math is incompatible with L</"bignum"> and L</"bigrat"> and will likely
result in NaN.

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
