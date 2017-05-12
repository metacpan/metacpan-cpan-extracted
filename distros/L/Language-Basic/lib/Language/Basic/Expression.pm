package Language::Basic::Expression;
# Part of Language::Basic by Amir Karger (See Basic.pm for details)

=pod

=head1 NAME

Language::Basic::Expression - Package to handle string, numeric, and
boolean expressions. 

=head1 SYNOPSIS

See L<Language::Basic> for the overview of how the Language::Basic module
works. This pod page is more technical.

    # Given an LB::Token::Group, create an expression I<and> parse it
    my $exp = new LB::Expression::Arithmetic $token_group;
    # What's the value of the expression?
    print $exp->evaluate;
    # Perl equivalent of the BASIC expression
    print $exp->output_perl;

Expressions are basically the building blocks of Statements, in that every
BASIC statement is made up of keywords (like GOTO, TO, STEP) and expressions.
So expressions include not just the standard arithmetic and boolean expressions
(like 1 + 2), but also lvalues (scalar variables or arrays), functions, and
constants. See L<Language::Basic::Syntax> for details on the way expressions
are built.

=head1 DESCRIPTION

BASIC expressions are represented by various objects of subclasses of
Language::Basic::Expression. Most LB::Expressions are in turn made up of other
LB::Expressions. For example an LBE::Arithmetic may be made up of two
LBE::Multiplicative and a "plus". "Atoms" (indivisible LBE's) include
things like LBE::Constants and LBE::Lvalues (variables).

=cut

use strict;
use Language::Basic::Common;

# sub-packages
{
package Language::Basic::Expression::Logical_Or;
package Language::Basic::Expression::Logical_And;
package Language::Basic::Expression::Relational;

package Language::Basic::Expression::Arithmetic;
package Language::Basic::Expression::Multiplicative;
package Language::Basic::Expression::Unary;

package Language::Basic::Expression::Lvalue;
package Language::Basic::Expression::Arglist;
package Language::Basic::Expression::Function;
package Language::Basic::Expression::Constant;

package Language::Basic::Expression::Numeric;
package Language::Basic::Expression::String;
package Language::Basic::Expression::Boolean;
}

# No sub new. Each class must have its own

# Most expressions have a "return type" that's String, Boolean, or Numeric.
# (Arglists don't, since they hold a list of expressions.)
#
# An arithmetic expression is a LBE::Arithmetic::Numeric if it's made up
# of LBE::Multiplicative::Numeric expressions, but LBE::Arithmetic::String
# if it's got a LBE::Unary::String in it. We never mix
# expression types (except within Arglists)
#
# This sub therefore blesses an object to its String/Numeric/Boolean subclass
# depending on the type of the sub-expression (and returns the newly blessed
# object.)
#
# Usually the sub-expression is itself an LB::Expression, but not always.
# We test for subexps of, e.g., LB::String rather than LBE::String,
# because we may be setting return type based on a LB::Variable::String or
# LB::Function::String, which aren't LB::Expressions.
#
# Arg0 is the thing to bless, arg1 is the subexp
sub set_return_type {
    my $self = shift;
    my $class = ref($self);
    # If we already are blessed, don't rebless!
    foreach (qw(String Numeric Boolean)) {
	return $self if $self->isa("Language::Basic::Expression::$_");
    }

    my $subexp = shift;
    my $type; # Return type
    foreach (qw(String Numeric Boolean)) {
	# LB::Function::String
	if ($subexp->isa("Language::Basic::$_")) {
	    $type = $_;
	    last;
	}
    }
    unless (defined $type) {die "Error refining $class to ",ref($subexp),"\n";}

    #print "self, class, type is 1 $self 2 $class 3 $type\n";
    # Note: "$class::$type" breaks!
    my $subclass = $class . "::$type";
    # TODO assert that class actually exists! E.g., call
    # $self->isa(LBE)
    bless $self, $subclass;
}

######################################################################

=pod

=head2 The LBE hierarchy

A bunch of LBE subclasses represent various kinds of BASIC expressions.
These subclasses closely follow the BASIC syntax diagram. 

Expressions can be classified in two ways, which are sort of vertical and
horizontal. One classification method is what subexpressions (if any) an
expression is made of. For example, an Arith. Exp. is made up of one or more
Mult. Exps. connected by plus or minus signs, while a Mult. Exp. is made up of
one or more Unary Exps. This is a hierarchical (or vertical) distinction,
important for building up the tree of objects that represent a BASIC
expression.

(Note that not all levels in the hierarchy have to be filled. We don't
bother making an Arith. Exp. which contains just one Mult. Exp. which contains
just one Unary Exp. Instead, we just use the Unary Exp. itself (when it's
safe to do so!)

The second way of classifying expressions is by their return type. A String
Exp. is a string constant, a string variable, a string function, or some other
expression whose value when evaluated will be a string. A Numeric Exp.
evaluates to a number, and a Boolean to a True or False value.  This
distinction is important for typechecking and finding syntax errors in BASIC
code.  (Note that in BASIC -- unlike Perl or C -- you can't "cast" a boolean
value into an integer or string. This actually makes parsing more difficult.)

Some expressions don't exactly fit any of these distinctions.  For example, an
Arglist evaluates to a list of expressions, each of which may be Numeric or
Boolean.


=head2 subclass methods

Each subclass has (at least) three methods: 

=over 4

=item new

The "new" method takes a class and a Token::Group (and possibly some other
args).  It eats one or more Tokens from it, parsing them, creating a new object
of that class I, and setting various fields in that object, which it returns.
If the tokens don't match the class, "new" returns undef.

If an expression contains just one subexpression often we'll just return the
subexpression.  So if an Arith. Exp.  contains just one Mult. Exp., we'll just
return the LBE::Multiplicative object and I<not> an LBE::Arithmetic object.

=item evaluate

Actually calculates the value of the expression. For a string
or numeric constant or variable, that just means taking the stored value
of that object. For other Expressions, you actually need to do math.

=item output_perl

Gives a string with the Perl equivalent to a BASIC expression. "1+2" is
converted to "1+2", but "A" becomes "$a", "A$" becomes "$a_str", and
function calls may be even more complicated.

=back

=head2 LBE subclasses

The hierarchical list of subclasses follows:

=over 4

=cut

=item Arithmetic

An arithmetic expression is a set of multiplicative expressions connected by
plus or minus signs. (String expressions can only be connected by plus,
which is the BASIC concatenation operator.)

=cut

# In BASIC, Arithmetic expressions can't contain Boolean expressions.
# However, parentheses can confuse things.
# LBE::Relational is one of:
# (1) LBE::Arithmetic Rel. Op. LBE::Arithmetic
# (2) (Logical Or)
# It calls LBE::Arithmetic::new with "maybe_boolean" sometimes, to tell
# LBEA::new that if it finds a (parenthesized) Boolean expression, it's
# just case #2 above. (Otherwise, a Boolean subexpression is an error.)
{
package Language::Basic::Expression::Arithmetic;
@Language::Basic::Expression::Arithmetic::ISA = qw(Language::Basic::Expression);
use Language::Basic::Common;

sub new {
# The while loop is necessary in case we have an expression like 1+2+3 
# It will effectively evaluate the +, - operators left to right 
    my $class = shift;
    my $token_group = shift;
    my $maybe_boolean = shift;
    if (defined($maybe_boolean) && $maybe_boolean ne "maybe_boolean") {
	Exit_Error("Internal Error: Weird arg '$maybe_boolean' to LBE::Arithmetic::new");
    }

    my $exp = new Language::Basic::Expression::Multiplicative 
	($token_group, $maybe_boolean);
    if ($exp->isa("Language::Basic::Expression::Boolean")) {
        if ($maybe_boolean) {
	    return $exp;
	} else {
	    Exit_Error("Syntax Error: Expected non-Boolean Expression!");
	}
    }

    my (@exps, @ops);
    push @exps, $exp;
    while (defined (my $tok = 
	    $token_group->eat_if_class("Arithmetic_Operator"))) {
	push @ops, $tok->text;
	$exp = new Language::Basic::Expression::Multiplicative $token_group;
	if ($exp->isa("Language::Basic::Expression::Boolean")) {
	    Exit_Error("Syntax Error: Expected non-Boolean Expression!");
	}
	push @exps, $exp;
    } # end while

    # Don't bother making an Arith. Exp. object if there's just one Mult. Exp.
    # Return the Mult. Exp. instead.
    return $exp unless @ops;

    # Otherwise, we want to create the Arith. Exp.
    my $self = {};
    $self->{"expressions"} = \@exps;
    $self->{"operations"} = \@ops;
    bless $self, $class;

    # Bless to LBEA::String or Numeric
    $self->set_return_type($exp);
    return $self;
} # end sub Language::Basic::Expression::Arithmetic::new

package Language::Basic::Expression::Arithmetic::String;
@Language::Basic::Expression::Arithmetic::String::ISA = 
    qw(Language::Basic::Expression::Arithmetic
       Language::Basic::Expression::String);

sub evaluate {
    my $self = shift;
    my @exps = @{$self->{"expressions"}};
    # Ops ought to be all pluses, since that's all BASIC can do.
    my @ops = @{$self->{"operations"}};

    my $exp = (shift @exps)->evaluate;
    while (my $op = shift @ops) {
	my $exp2 = (shift @exps)->evaluate;
	if ($op eq '+') {
	    $exp .= $exp2;
	} else {
	    die "Unknown op in LBE::Arithmetic::String::evaluate!\n";
	}
    } # end while
    return($exp);
} # end sub Language::Basic::Expression::Arithmetic::String::evaluate

sub output_perl {
    my $self = shift;
    my @exps = @{$self->{"expressions"}};
    my @ops = @{$self->{"operations"}};

    my $ret = (shift @exps)->output_perl;
    while (my $op = shift @ops) {
	if ($op eq "+") {
	    my $exp = (shift @exps)->output_perl;
	    $ret .= " . " . $exp;
	} else {
	    die "Unknown op in LBE::Arithmetic::String::output_perl!\n";
	}
    } # end while
    return($ret);
} # end sub Language::Basic::Expression::Arithmetic::String::output_perl

package Language::Basic::Expression::Arithmetic::Numeric;
@Language::Basic::Expression::Arithmetic::Numeric::ISA = 
    qw(Language::Basic::Expression::Arithmetic
       Language::Basic::Expression::Numeric);

sub evaluate {
    my $self = shift;
    my @exps = @{$self->{"expressions"}};
    my @ops = @{$self->{"operations"}};

    my $exp = (shift @exps)->evaluate;
    while (my $op = shift @ops) {
	my $exp2 = (shift @exps)->evaluate;
	if ($op eq '+') {
	    $exp = $exp + $exp2;
	} else { # minus
	    $exp = $exp - $exp2;
	}
    } # end while
    return($exp);
} # end sub Language::Basic::Expression::Arithmetic::Numeric::evaluate

sub output_perl {
    my $self = shift;
    my @exps = @{$self->{"expressions"}};
    my @ops = @{$self->{"operations"}};

    my $ret = (shift @exps)->output_perl;
    while (my $op = shift @ops) {
	my $exp = (shift @exps)->output_perl;
	$ret .= $op . $exp;
    } # end while
    return($ret);
} # end sub Language::Basic::Expression::Arithmetic::Numeric::output_perl

} # end package Language::Basic::Expression::Arithmetic

=item Multiplicative

a set of unary expressions connected by '*' or '/'.  

=cut

{
package Language::Basic::Expression::Multiplicative;
@Language::Basic::Expression::Multiplicative::ISA = qw(Language::Basic::Expression);
use Language::Basic::Common;

sub new {
    my $class = shift;
    my $token_group = shift;
    my $maybe_boolean = shift;
    if (defined($maybe_boolean) && $maybe_boolean ne "maybe_boolean") {
	Exit_Error("Internal Error: Weird arg '$maybe_boolean' to LBE::Multiplicative::new");
    }

    my $exp = new Language::Basic::Expression::Unary 
	($token_group, $maybe_boolean);
    if ($exp->isa("Language::Basic::Expression::Boolean")) {
        if ($maybe_boolean) {
	    return $exp;
	} else {
	    Exit_Error("Syntax Error: Expected non-Boolean Expression!");
	}
    }

    my (@exps, @ops);
    push @exps, $exp;
    while (defined (my $tok = 
	    $token_group->eat_if_class("Multiplicative_Operator"))) {
	push @ops, $tok->text;
	$exp = new Language::Basic::Expression::Unary $token_group;
	if ($exp->isa("Language::Basic::Expression::Boolean")) {
	    Exit_Error("Syntax Error: Expected non-Boolean Expression!");
	}
	push @exps, $exp;
    } # end while

    # Don't bother making a Mult. Exp. object if there's just one Unary Exp.
    # Return the Unary Exp. instead.
    # Note that this will definitely happen if $exp is a String.
    return $exp unless @ops;

    # Otherwise, we want to create the Mult. Exp.
    my $self = {};
    $self->{"expressions"} = \@exps;
    $self->{"operations"} = \@ops;
    bless $self, $class;

    # Bless to LBEM::String or Numeric
    $self->set_return_type($exp);
    return $self;
} # end sub Language::Basic::Expression::Multiplicative::new

sub evaluate {
    my $self = shift;
    my @exps = @{$self->{"expressions"}};
    my @ops = @{$self->{"operations"}};

    my $exp = (shift @exps)->evaluate;
    while (my $op = shift @ops) {
	my $exp2 = (shift @exps)->evaluate;
	if ($op eq '*') {
	    $exp = $exp * $exp2;
	} else {
	    $exp = $exp / $exp2;
	}
    } # end while
    return($exp);
} # end sub Language::Basic::Expression::Multiplicative::evaluate

sub output_perl {
    my $self = shift;
    my @exps = @{$self->{"expressions"}};
    my @ops = @{$self->{"operations"}};

    my $ret = (shift @exps)->output_perl;
    while (my $op = shift @ops) {
	my $exp = (shift @exps)->output_perl;
	$ret .= $op . $exp;
    } # end while
    return($ret);
} # end sub Language::Basic::Expression::Multiplicative::output_perl

# Sub packages
package Language::Basic::Expression::Multiplicative::Numeric;
@Language::Basic::Expression::Multiplicative::Numeric::ISA = 
    qw(Language::Basic::Expression::Multiplicative
       Language::Basic::Expression::Numeric);
# Note that there can't possibly be an LBEM::String. LBEM::new will just 
# return an LBE::Unary, since there are no string multiplying ops to find.
} # end package Language::Basic::Expression::Multiplicative

=item Unary

a variable, a function, a string or numeric constant, or an arithmetic
expression in parentheses, potentially with a unary minus sign.

=cut

{
package Language::Basic::Expression::Unary;
@Language::Basic::Expression::Unary::ISA = qw(Language::Basic::Expression);
use Language::Basic::Common;

sub new {
    my $class = shift;
    my $token_group = shift;
    # Fields:
    #     nested	This Expression contains a parenthesized exp.
    #     minus		This Exp. has a unary minus in front of it
    my $self = { 
        "nested" => "",
	"minus" => "",
    };

    # If we're inside a Relational Exp., then a parenthetical exp. may
    # be either Boolean or non-Boolean. Otherwise, it has to be non-Boolean
    my $maybe_boolean = shift;
    if (defined($maybe_boolean) && $maybe_boolean ne "maybe_boolean") {
	Exit_Error("Internal Error: Weird arg '$maybe_boolean' to LBE::Unary::new");
    }

    # unary minus in the expression?
    $self->{"minus"} = 1 if defined($token_group->eat_if_string("-"));

    my $unary;
    my $try;
    # if a parentheses, (recursively) parse what's inside
    # If $maybe_boolean, then a paren'ed expression might be a Boolean exp., 
    # so call LBE::Logical_Or (highest level Boolean exp.)
    # However, in most cases, it'll be a non-Boolean, so call with
    # "maybe_arithmetic" flag, which tells LBE::LO not to be surprised
    # if it finds an arithmetic exp.
    if (defined($token_group->eat_if_class("Left_Paren"))) {
	$self->{"nested"} = 1;
	$try = new Language::Basic::Expression::Logical_Or 
	    ($token_group, "maybe_arithmetic");
	# Skip End Paren
	defined($token_group->eat_if_class("Right_Paren")) or
	     Exit_Error("Expected ')' to match '('!");
	# if we found a Boolean, make sure we're allowed to have one.
	if ($try->isa("Language::Basic::Expression::Boolean") && 
		!$maybe_boolean) {
	    Exit_Error("Syntax Error: Expected non-Boolean Expression!");
	}
	$unary = $try

    # OR it's a String or Numeric function
    # NOTE that LBEF::new had better not eat the word if it returns undef!
    } elsif (defined ($try = 
	    new Language::Basic::Expression::Function $token_group)) {
	$unary = $try;

    # OR it's a String or Numeric variable
    } elsif (defined ($try = 
	    new Language::Basic::Expression::Lvalue $token_group)) {
	$unary = $try;

    # OR it's a String or Numeric constant
    } elsif (defined ($try = 
	    new Language::Basic::Expression::Constant $token_group)) {
	$unary = $try;

    # Or die
    } else {
	my $tok = $token_group->lookahead or
	    Exit_Error("Found nothing when expected Unary Expression!");
        Exit_Error("Unknown unary expression starts with '", $tok->text,"'");
    }
    #print "unary ref is ",ref($unary),"\n";

    # If it's just an Lvalue, say, then return the Lvalue object rather
    # than making a Unary out of it. Can't do that if we're nested or minused.
    if ($self->{"nested"} || $self->{"minus"}) {
	$self->{"expression"} = $unary;
	bless $self, $class;
	# Bless to LBEU::String or Numeric or Boolean
	$self->set_return_type($unary);
	return $self;
    } else {
        return $unary;
    }
} # end Language::Basic::Expression::Unary::new

sub evaluate {
    my $self = shift;
    my $exp = $self->{"expression"};

    my $value = $exp->evaluate;
    $value = -$value if $self->{"minus"};
    return($value);
} # end sub Language::Basic::Expression::Unary::evaluate

sub output_perl {
    my $self = shift;
    my $ret = $self->{"minus"} ?  "-" : "";
    my $exp = $self->{"expression"};
    my $out = $exp->output_perl;
    if ($self->{"nested"}) {
        $out = "(" . $out . ")";
    }
    $ret .= $out;
    return($ret);
} # end sub Language::Basic::Expression::Unary::output_perl

# Sub packages
package Language::Basic::Expression::Unary::Numeric;
@Language::Basic::Expression::Unary::Numeric::ISA = 
    qw(Language::Basic::Expression::Unary
       Language::Basic::Expression::Numeric);
package Language::Basic::Expression::Unary::String;
@Language::Basic::Expression::Unary::String::ISA = 
    qw(Language::Basic::Expression::Unary
       Language::Basic::Expression::String);
package Language::Basic::Expression::Unary::Boolean;
@Language::Basic::Expression::Unary::Boolean::ISA = 
    qw(Language::Basic::Expression::Unary
       Language::Basic::Expression::Boolean);
} # end package Language::Basic::Expression::Unary

######################################################################

=item Constant

a string or numeric constant, like "17" or 32.4

=cut

{
package Language::Basic::Expression::Constant;
@Language::Basic::Expression::Constant::ISA = qw(Language::Basic::Expression);

# Returns a LBE::Constant::* subclass or undef
sub new {
    my $class = shift;
    my $token_group = shift;
    my ($const, $try);
    if (defined ($try = 
	    new Language::Basic::Expression::Constant::Numeric $token_group)) {
	$const = $try;
    } elsif (defined ($try = 
	    new Language::Basic::Expression::Constant::String $token_group)) {
	$const = $try;
    } else {
        return undef;
    }

    return $const;
} # end Language::Basic::Expression::Constant::new

sub evaluate {return shift->{"expression"}->evaluate; }

package Language::Basic::Expression::Constant::Numeric;
@Language::Basic::Expression::Constant::Numeric::ISA = 
    qw(Language::Basic::Expression::Constant
       Language::Basic::Expression::Numeric);

sub new {
    my $class = shift;
    my $token_group = shift;
    if (defined (my $tok = 
            $token_group->eat_if_class("Numeric_Constant"))) {
	my $self = {"value" => $tok->text + 0};
	bless $self, $class; # and return it
    } else {
        return undef;
    }
} # end sub Language::Basic::Expression::Constant::Numeric::new

sub evaluate { return shift->{"value"} }

sub output_perl {return shift->{"value"}}

package Language::Basic::Expression::Constant::String;
@Language::Basic::Expression::Constant::String::ISA = 
    qw(Language::Basic::Expression::Constant
       Language::Basic::Expression::String);

sub new {
    my $class = shift;
    my $token_group = shift;
    if (defined (my $tok = 
            $token_group->eat_if_class("String_Constant"))) {
	(my $text = $tok->text) =~ s/^"(.*?)"/$1/;
	my $self = {"value" => $text};
	bless $self, $class; # and return it
    } else {
	# TODO handle unquoted string for Input, Data statements
	warn "Currently only understand quoted strings for String Constant";
        return undef;
    }
} # end sub Language::Basic::Expression::Constant::String::new

sub evaluate { return shift->{"value"} }

# Don't return in single quotes, because single quotes may be in a BASIC
# string constant. Instead use quotemeta. But don't really use quotemeta,
# because it quotes too much.
sub output_perl {
    my $self = shift;
    my $str = $self->{"value"};
    $str =~ s/([\$%@*&])/\\$1/g; # poor man's quotemeta
    return '"' . $str . '"';
} # end sub Language::Basic::Expression::Constant::String::output_perl

} # end package Language::Basic::Expression::Constant

######################################################################

=item Lvalue

a settable expression: a variable, X, or one cell in an array, A(17,Q). The
"variable" method returns the actual LB::Variable::Scalar object referenced by
this Lvalue.

=cut

{
package Language::Basic::Expression::Lvalue;
@Language::Basic::Expression::Lvalue::ISA = qw(Language::Basic::Expression);
use Language::Basic::Common;

# Sub-packages
{
package Language::Basic::Expression::Lvalue::Numeric;
@Language::Basic::Expression::Lvalue::Numeric::ISA = 
    qw(Language::Basic::Expression::Lvalue
       Language::Basic::Expression::Numeric);
package Language::Basic::Expression::Lvalue::String;
@Language::Basic::Expression::Lvalue::String::ISA = 
    qw(Language::Basic::Expression::Lvalue
       Language::Basic::Expression::String);
}

# Fields:
#    varptr - ref to the LB::Variable (::Array or ::Scalar) object. Note
#        that it does NOT ref a particular cell in an LBV::Array object!
#    arglist - a set of Arithmetic Expressions describing which exact cell
#        in an LBV::Array to get. undef for a LBV::Scalar
sub new {
    my $class = shift;
    my $token_group = shift;
    my $self = {};

    defined (my $tok = 
	    $token_group->eat_if_class("Identifier")) or
	    return undef;
    my $name = $tok->text;

    # read ( Arglist ) if it exists
    # By default, though, it's a scalar, and has no ()
    $self->{"arglist"} = undef;
    if (defined (my $arglist = 
	    new Language::Basic::Expression::Arglist $token_group)) {
	$self->{"arglist"} = $arglist;
    }

    # Look up the variable by name in the (Array or Scalar) variable storage.
    # (Also, create the Variable if it doesn't yet exist.)
    my $var = &Language::Basic::Variable::lookup($name, $self->{"arglist"});
    $self->{"varptr"} = $var;
    $self->{"name"} = $name;

    bless $self, $class;
    # Is it a string or numeric lvalue?
    $self->set_return_type($var);
    return $self;
} # end sub Language::Basic::Expression::Lvalue::new

sub evaluate { 
    my $self = shift;
    # This automatically gets the correct array cell if necessary
    my $var = $self->variable;
    my $value = $var->value;
    return $value;
} # end sub Language::Basic::Expression::Lvalue::evaluate

# returns a variable, e.g. for setting in a Let or changing in a Next
# Note that it always returns a LB::Variable::Scalar object. If the
# variable in this expression is an Array, it returns one cell from the array.
sub variable { 
    my $self = shift;
    my $var = $self->{"varptr"};
    # if Arglist exists, evaluate each arith. exp. in it and get that cell
    # from the Array
    if (defined (my $arglist = $self->{"arglist"})) {
	my @args = $arglist->evaluate;
	$var = $var->get_cell(@args);
    }

    return $var;
} # end sub Language::Basic::Expression::Lvalue::variable

sub output_perl {
    my $self = shift;
    my $name = $self->{"name"};
    $name =~ s/\$$/_str/; # make name perl-like
    my $ret = '$' . lc($name);
    if (defined $self->{"arglist"}) {
	my $args = join("][", ($self->{"arglist"}->output_perl));
	$ret .= "[" . $args . "]";
    }
    return $ret;
} # end sub Language::Basic::Expression::Lvalue::output_perl

} # end package Language::Basic::Expression::Lvalue

######################################################################

=item Function

Either an Intrinsic or a User-Defined function.

=cut

#
# Fields:
#    function - ref to the LB::Function (::Intrinsic or ::Defined) used
#        by this expression
#    arglist - a set of Arithmetic Expressions describing the arguments
#        to pass to the function
{
package Language::Basic::Expression::Function;
@Language::Basic::Expression::Function::ISA = qw(Language::Basic::Expression);
use Language::Basic::Common;

# Sub-packages
{
package Language::Basic::Expression::Function::Numeric;
@Language::Basic::Expression::Function::Numeric::ISA = 
    qw(Language::Basic::Expression::Function
       Language::Basic::Expression::Numeric);
package Language::Basic::Expression::Function::String;
@Language::Basic::Expression::Function::String::ISA = 
    qw(Language::Basic::Expression::Function
       Language::Basic::Expression::String);
}

# Arg0, Arg1 are the object and a ref to the string being parsed, as usual.
# Arg2, if it exists, says we're in a DEF statement, so that if the
# function doesn't exist, we should create it rather than returning undef.
sub new {
    my $class = shift;
    my $token_group = shift;
    my $self = {};

    # Don't eat it if it's not a true function name (could be an lvalue)
    my $tok = $token_group->lookahead;
    return undef unless $tok->isa("Language::Basic::Token::Identifier");
    my $name = $tok->text;
    my $defining = (defined (my $exp = shift));

    # Look up the function name
    # If the function doesn't exist, the word is a variable or something...
    # Alternatively, if there was a second argument to parse, then we're
    # in a DEF statement & should create the function.
    my $func;
    if ($defining) {
	# TODO should this check be somewhere else, so that we can
	# give a more descriptive error message in Statement::Def::new?
	return undef unless $name =~ /^FN/;
        $func = new Language::Basic::Function::Defined $name;
    } else {
	$func = &Language::Basic::Function::lookup($name) or return undef;
    }
    $self->{"function"} = $func;

    #Now that we know it's a function, eat the token
    $token_group->eat;

    # read ( Arglist )
    # TODO Actually, whether or not we're defining, we should just read
    # an LBE::Arglist here. If $defining, define() can make sure all args
    # are actually Lvalues containing Scalar Variables. However, this
    # requires that Arglist has Lvalues, rather than Arith. Exp.'s
    # containing (ME's containing...) Lvalues.
    if ($defining) {
	# Empty parens aren't allowed! (and \s* has been removed by lexing)
	defined($token_group->eat_if_class("Left_Paren")) or
	    Exit_Error("Function must take at least one argument.");
	my @args;
	do {
	    my $arg = new Language::Basic::Expression::Lvalue $token_group;
	    push @args, $arg;
	} while (defined $token_group->eat_if_string(","));
	defined($token_group->eat_if_class("Right_Paren")) or
	     Exit_Error("Expected ')' to match '('!");

        # Declare the number & type of args in the subroutine
	$func->declare (\@args);

    } else {
	my $arglist = new Language::Basic::Expression::Arglist $token_group
	    or Exit_Error("Function without arglist!");
	# check if the number or type of args is wrong.
	$func->check_args($arglist);
	$self->{"arglist"} = $arglist;
    }

    bless $self, $class;
    # Is it a string or numeric Function?
    $self->set_return_type($func);
    return $self;
} # end sub Language::Basic::Expression::Function::new

sub evaluate { 
    my $self = shift;
    my $func = $self->{"function"};
    my $arglist = $self->{"arglist"};
    # Note we tested number & type of args in new
    my @args = $arglist->evaluate;
    my $value = $func->evaluate(@args);
    return $value;
} # end sub Language::Basic::Expression::Function::evaluate

sub output_perl {
    my $self = shift;
    # Function name
    my $func = $self->{"function"};
    my $ret = $func->output_perl;
    # If it's either a user-defined function or a BASIC intrinsic (that
    # doesn't have a Perl equivalent), add a &
    if ($ret =~ /(fun|bas)$/) {$ret = '&' . $ret}

    # Function args
    $ret .= "(";
    
    my @args = $self->{"arglist"}->output_perl;
    $ret .= join(", ", @args);
    $ret .= ")";
    return $ret;
}

} # end package Language::Basic::Expression::Function

=item Arglist

a list of arguments to an array or function

=cut

{
package Language::Basic::Expression::Arglist;
@Language::Basic::Expression::Arglist::ISA = qw(Language::Basic::Expression);
use Language::Basic::Common;

sub new {
    my $class = shift;
    my $token_group = shift;
    my $self = {};

    # Has to start with paren
    defined($token_group->eat_if_class("Left_Paren")) or
	return undef;
    # Eat args
    my @args = ();
    do {
	my $arg = new Language::Basic::Expression::Arithmetic $token_group;
	# TODO test that arg is a Scalar!
	push @args, $arg;
    } while (defined($token_group->eat_if_string(",")));

    # Has to end with paren
    defined($token_group->eat_if_class("Right_Paren")) or
	Exit_Error("Arglist without ')' at end!");
    unless (@args) {Exit_Error("Empty argument list ().")}

    $self->{"arguments"} = \@args;
    bless $self, $class;
} # end sub Language::Basic::Expression::Arglist::new

# Returns a LIST of values
sub evaluate {
    my $self = shift;
    my @values = map {$_->evaluate} @{$self->{"arguments"}};
    return @values;
} # end sub Language::Basic::Expression::Arglist::evaluate

# Note this returns an ARRAY of args. Messes up the output_perl paradigm,but
# functions & arrays need to do different things to the args.
sub output_perl {
    my $self = shift;
    return map {$_->output_perl} @{$self->{"arguments"}};
} # end sub Language::Basic::Expression::Arglist::output_perl
} # end package Language::Basic::Expression::Arglist

######################################################################
# Boolean stuff
# Booleans don't care whether the stuff in them is String or Numeric,
# so no sub-packages are needed.

=item Logical_Or

a set of Logical_And expressions connected by "OR"

=cut

# In BASIC, Boolean expressions can't contain non-Boolean expressions
# except for Relational Exps. (which have two Arithmetic Exps. separated by
# a Rel. Op.)
# However, parentheses can confuse things.
# LBE::Unary is one of:
# (1) A constant, variable, function, etc.
# (2) (Arithmetic Exp.)
# (3) (Logical Or)
# Unary::new calls LBE::Logical_Or::new with "maybe_arithmetic" sometimes, to 
# tell LBELO::new that if it finds a (parenthesized) non-Boolean expression, 
# it's just case #2 above. (Otherwise, a non-Boolean subexpression is an error.)
{
package Language::Basic::Expression::Logical_Or;
@Language::Basic::Expression::Logical_Or::ISA = 
    qw(Language::Basic::Expression::Boolean);
use Language::Basic::Common;

sub new {
    # No "operators" field is necessary since operators must all be "OR"
    my $class = shift;
    my $token_group = shift;
    my $maybe_arithmetic = shift;
    if (defined($maybe_arithmetic) && $maybe_arithmetic ne "maybe_arithmetic") {
	Exit_Error("Internal Error: Weird arg '$maybe_arithmetic' to LBE::Logical_Or::new");
    }

    my $exp = new Language::Basic::Expression::Logical_And 
	($token_group, $maybe_arithmetic); # TODO ... or Error...
    if (! $exp->isa("Language::Basic::Expression::Boolean")) {
        if ($maybe_arithmetic) {
	    return $exp;
	} else {
	    Exit_Error("Syntax Error: Expected Boolean Expression");
	}
    }

    my @exps;
    push @exps, $exp;
    while (defined ($token_group->eat_if_string("OR"))) {
	$exp = new Language::Basic::Expression::Logical_And $token_group;
	if (! $exp->isa("Language::Basic::Expression::Boolean")) {
	    Exit_Error("Syntax Error: Expected Boolean Expression!");
	}
	push @exps, $exp;
    } # end while

    # Don't bother making a Logical_Or object if there's just one Logical_And
    return $exp if @exps == 1;

    # Otherwise, we want to create the Logical_Or
    my $self = {"expressions" => \@exps};
    bless $self, $class;
} # end sub Language::Basic::Expression::Logical_Or::new

sub evaluate {
    my $self = shift;
    my @exps = @{$self->{"expressions"}};

    my $exp = (shift @exps)->evaluate;
    # TODO stop calculating when we find a true one?
    while (defined(my $exp2 = shift @exps)) {
	$exp = $exp || $exp2->evaluate;
    } # end while
    return($exp);
} # end sub Language::Basic::Expression::Logical_Or::evaluate

sub output_perl {
    my $self = shift;
    my @exps = @{$self->{"expressions"}};

    my $ret = (shift @exps)->output_perl;
    while (defined(my $exp = shift @exps)) {
	$ret .= " || " . $exp->output_perl;
    } # end while
    return($ret);
} # end sub Language::Basic::Expression::Logical_Or::output_perl

} # end package Language::Basic::Expression::Logical_Or

=item Logical_And

a set of Relational expressions connected by "AND"

=cut

{
package Language::Basic::Expression::Logical_And;
@Language::Basic::Expression::Logical_And::ISA = 
    qw(Language::Basic::Expression::Boolean);
use Language::Basic::Common;

sub new {
    # No "operators" field is necessary since operators must all be "AND"
    my $class = shift;
    my $token_group = shift;
    my $maybe_arithmetic = shift;
    if (defined($maybe_arithmetic) && $maybe_arithmetic ne "maybe_arithmetic") {
	Exit_Error("Internal Error: Weird arg '$maybe_arithmetic' to LBE::Logical_And::new");
    }

    my $exp = new Language::Basic::Expression::Relational 
	($token_group, $maybe_arithmetic);
    if (! $exp->isa("Language::Basic::Expression::Boolean")) {
        if ($maybe_arithmetic) {
	    return $exp;
	} else {
	    Exit_Error("Syntax Error: Expected Boolean Expression!");
	}
    }

    my @exps;
    push @exps, $exp;
    while (defined ($token_group->eat_if_string("AND"))) {
	$exp = new Language::Basic::Expression::Relational $token_group;
	if (! $exp->isa("Language::Basic::Expression::Boolean")) {
	    Exit_Error("Syntax Error: Expected Boolean Expression!");
	}
	push @exps, $exp;
    } # end while

    # Don't bother making a Logical_And object if there's just one Relational
    return $exp if @exps == 1;

    # Otherwise, we want to create the Logical_And
    my $self = {"expressions" => \@exps};
    bless $self, $class;
} # end sub Language::Basic::Expression::Logical_And::new

sub evaluate {
    my $self = shift;
    my @exps = @{$self->{"expressions"}};

    my $exp = (shift @exps)->evaluate;
    # TODO stop calculating when we find a true one?
    while (defined(my $exp2 = shift @exps)) {
	$exp = $exp && $exp2->evaluate;
    } # end while
    return($exp);
} # end sub Language::Basic::Expression::Logical_And::evaluate

sub output_perl {
    my $self = shift;
    my @exps = @{$self->{"expressions"}};

    my $ret = (shift @exps)->output_perl;
    while (defined(my $exp = shift @exps)) {
	$ret .= " && " . $exp->output_perl;
    } # end while
    return($ret);
} # end sub Language::Basic::Expression::Logical_And::output_perl

} # end package Language::Basic::Expression::Logical_And

=item Relational

A relational expression, like "A>B+C", optionally with a NOT in front of it.

=cut

{
package Language::Basic::Expression::Relational;
@Language::Basic::Expression::Relational::ISA = 
    qw(Language::Basic::Expression::Boolean);
use Language::Basic::Common;

# Usually, an LBE::Relational is just LBE::Arithmetic Rel. Op. LBE::Arithmetic
# However, if the first sub-expression in the LBE::Relational is parenthesized,
# it could be either
# (1) (Logical Or Exp.)  --- E.g. IF (A>B OR C>D) THEN...
# (2) (Arith. Exp.) --- E.g. IF (A+1)>B THEN...
# So we call the first LBE::Arithmetic::new with "maybe_boolean", so that
# it knows it may find a Boolean sub-expression
# Note that in case (1), we don't need to look for a Rel. Op., because
# IF (A>B OR C>D) > 2 is illegal.
#
# Rel. Exp. usually has two expressions in the "expressions" field, and
# an operator in the "operator" field. However, in case (1) above, there will
# only be one (Boolean) expression, and no op.

sub new {
    my ($class, $token_group) = (shift, shift);
    my $self = {};
    my $maybe_arithmetic = shift;
    if (defined($maybe_arithmetic) && $maybe_arithmetic ne "maybe_arithmetic") {
	Exit_Error("Internal Error: Weird arg '$maybe_arithmetic' to LBE::Relational::new");
    }

    # "NOT" in the expression?
    $self->{"not"} = defined($token_group->eat_if_string("NOT"));

    my $e = new Language::Basic::Expression::Arithmetic 
        ($token_group, "maybe_boolean")
        or Exit_Error("Unexpected text at beginning of Rel. Exp.");
    push @{$self->{"expressions"}}, $e;

    # Did we find a parenthesized Boolean exp? Then just return it.
    # Don't even look for a rel. op. since it would be illegal! 
    if ($e->isa("Language::Basic::Expression::Boolean")) {
        # TODO return $e instead of blessing unless self->not?
	bless $self, $class;
	return $self;
    }

    # Read the Rel. Op. 
    my $tok;
    if (!defined ($tok = $token_group->eat_if_class("Relational_Operator"))) {
	# Found a parenthesized Arithmetic Exp.?
        if ($maybe_arithmetic) {
	    return $e; # Don't bother blessing & returning $self
	} else {
	    Exit_Error("Syntax Error: No Relational Operator in Rel. Exp.");
	}
    }

    my $op = $tok->text;

    # Note: $e2 isn't allowed to be arithmetic, so no maybe_arithmetic arg
    my $e2 = new Language::Basic::Expression::Arithmetic $token_group or
        Exit_Error("Unexpected text in Rel. Exp. after '$op'");
    push @{$self->{"expressions"}}, $e2;

    # Convert BASIC ops to perlops
    my $num_op = {
        "="  => "==",
	">"  => ">",
	"<"  => "<",
	">=" => ">=",
	"<=" => "<=",
	"<>" => "!=",
    };
    my $string_op = {
        "="  => "eq",
	">"  => "gt",
	"<"  => "lt",
	">=" => "ge",
	"<=" => "le",
	"<>" => "ne",
    };
    my $trans = ($e->isa("Language::Basic::Expression::String")
        ? $string_op : $num_op);
    my $perlop = $trans->{$op} or Exit_Error("Unrecognized Rel. op. '$op'");
    $self->{"operator"} = $perlop;
    bless $self, $class;
} # end sub Language::Basic::Expression::Relational::new

sub evaluate {
# If this Rel. Exp. has a nested Boolean Exp. inside it, then just
# evaluate that (and NOT it if nec.)
# Otherwise, evaluate the two sides of the Rel. Exp. (each is non-Boolean
# exp -- either they're both arithmetic or they're both string) and
# compare them.
    my $self = shift;

    my @exps = @{$self->{"expressions"}};
    my $exp = shift @exps;
    my $e = $exp->evaluate;
    my $value;
    if (! $exp->isa("Language::Basic::Expression::Boolean")) {
	my $exp2 = shift @exps;
	my $e2 = $exp2->evaluate;

	my $perlop = $self->{"operator"};
	# I'm vainly hoping that Perl eval will get the same result BASIC would
	# Need to use \Q in case we say IF A$ = "\", which should really compare
	# with \\.
	my $perlexp = "\"\Q$e\E\" " . $perlop . " \"\Q$e2\E\"";
	$value = eval $perlexp;
	#print "exp is '$perlexp', value is '$value'\n";

    } else { # exp has a nested Boolean Exp. in it. There is no exp2
        $value = $e;
    }
    
    $value = !$value if $self->{"not"};
    return $value;
} # end sub Language::Basic::Expression::Relational::evaluate

sub output_perl {
    my $self = shift;
    my @exps = @{$self->{"expressions"}};
    my $exp = shift @exps;
    my $e = $exp->output_perl;

    my $ret;
    # "Normal" Rel. Exp., or nested Boolean exp.?
    if (! $exp->isa("Language::Basic::Expression::Boolean")) {
	my $exp2 = shift @exps;
	my $e2 = $exp2->output_perl;

	my $perlop = $self->{"operator"};
        $ret = join(" ",$e, $perlop, $e2);
    } else {
        $ret = $e;
    }

    if ($self->{"not"}) {
	# Don't add parens if it's already paren'd
        $ret = "(" . $ret . ")" unless $ret =~ /^\(.*\)$/;
	$ret = "!" . $ret;
    }

    return($ret);
} # end sub Language::Basic::Expression::Relational::output_perl

} # end package Language::Basic::Expression::Relational

{
# set ISA for "return type" classes
package Language::Basic::Expression::Numeric;
@Language::Basic::Expression::Numeric::ISA = qw
    (Language::Basic::Expression Language::Basic::Numeric);
package Language::Basic::Expression::String;
@Language::Basic::Expression::String::ISA = qw
    (Language::Basic::Expression Language::Basic::String);
package Language::Basic::Expression::Boolean;
@Language::Basic::Expression::Boolean::ISA = qw
    (Language::Basic::Expression Language::Basic::Boolean);
}

=pod

=back

=cut

1; # end package Language::Basic::Expression
