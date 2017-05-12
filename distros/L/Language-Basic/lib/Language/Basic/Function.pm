package Language::Basic::Function;
# Part of Language::Basic by Amir Karger (See Basic.pm for details)

=pod

=head1 NAME

Language::Basic::Function - Package to handle user-defined and intrinsic
Functions in BASIC.

=head1 SYNOPSIS

See L<Language::Basic> for the overview of how the Language::Basic module
works. This pod page is more technical.

A Function can be either an intrinsic BASIC function, like INT or CHR$,
or a user-defined function, like FNX (defined with the DEF command).

=head1 DESCRIPTION

The check_args method checks that the right number and type of function
arguments were input.

The evaluate method actually calculates the value of the function, given
certain arguments.

The lookup method looks up the function in the function lookup table.

The output_perl method returns a string that's the Perl equivalent to
the BASIC function.

=cut

# Fields:
#     arg_types - a string. If a function takes a String and two Numeric
#         arguments, the string will be "SNN". Like in Perl, a semicolon
#         separates required from optional arguments

use strict;
use Language::Basic::Common;

# sub-packages
{
package Language::Basic::Function::Intrinsic;
package Language::Basic::Function::Defined;
}

# Lookup table for functions
my %Table;

# This sub puts the function in the lookup table
sub new {
    my ($class, $name) = @_;

    my $self = {
        "name" => $name,
    } ;

    # Put this sub in lookup table
    $Table{$name} = $self;

    my $type = ($name =~ /\$$/) ? "String" : "Numeric";
    # Create a new subclass object, & return it
    my $subclass = $class . "::$type";
    bless $self, $subclass;
} # end sub Language::Basic::Function::new

# Lookup a function by name in the function table.
# This will (in theory) never be called before new has been called
# for function $name
sub lookup {
    my $name = shift;
    return $Table{$name};
} # end sub Language::Basic::Variable::lookup

# Check argument number and type. Exit_Error if there's a problem.
sub check_args {
    my ($self, $arglist) = @_;
    my @args = @{$arglist->{"arguments"}};
    # Test for several errors at once
    my $error = "";

    # Handle optional args
    my ($min_types, $max_types);
    my $types = $self->{"arg_types"};
    if ($types =~ s/(.*);/$1/) {
        $min_types = length($1);
    } else {
        $min_types = length($types);
    }
    $max_types = length($types);

    $error .= ("Wrong number of arguments to function\n") 
        unless @args <= $max_types && @args >= $min_types;
    # Now check each argument type
    foreach my $type (split (//, $types)) {
	my $arg = shift @args or last; # may be optional args
	# This should never happen, hence die, not Exit_Error
        ref($arg) =~ /(String|Numeric)$/ or 
	    die "Error in LBF::Defined::check_args";
	my $atype = substr($1,0,1);
	if ($atype ne $type) {
	    $error .= $type eq "N" ?
		"String argument given, Numeric required.\n" :
		"Numeric argument given, String required.\n";
	}
    }
    chomp($error); # Exit_Error will add last \n back in.
    Exit_Error($error) if $error;
} # end sub Language::Basic::Variable::check_args

=head2

Class Language::Basic::Function::Intrinsic

This class handles intrinsic BASIC functions.

=cut

#
# Fields:
#     subroutine - a ref to a sub that implements the BASIC routine in Perl
#         (assuming the args are in @_)
{
package Language::Basic::Function::Intrinsic;
@Language::Basic::Function::Intrinsic::ISA = qw(Language::Basic::Function);
use Language::Basic::Common;

=pod

The initialize method sets up BASIC's supported functions at the beginning
of the program. The all-important @Init holds a ref for each function
to an array holding: 
- the function name, 
- the number and type of arguments (in a Perl function prototype-like style), 
- a subref that performs the equivalent of the BASIC function, and 
- a string for the output_perl method. That string is either the name of an
  equivalent Perl function, like "ord" for BASIC's "ASC", or (if there is no
  exact equivalent) a BLOCK that performs the same action.
Adding intrinsic BASIC functions therefore involves adding to this array.

=cut

sub initialize {
    # The type is an N or S for each Numeric or String argument the
    # function takes.
    # funcstring is a string that gives the perl equivalent to the
    # BASIC function. (Used for output_perl) If it's just a word, then perl
    # and BASIC have exactly equivalent functions, which  makes the function
    # call much easier. Otherwise, it's something in {} that will become
    # a sub.
    # TODO it would be pretty sexy to have the subref and the funcstring
    # do the same thing (i.e., create the sub with an eval of funcstring).
    # Only reason so far I can think of not to is Exit_Error call in CHR$.
    # But I could create an Exit_Error routine in output perl script!
    my @Init = (
	# Numeric functions...
	["ASC", "S", sub {ord(shift)}, "ord" ],
	["INT", "N", sub {int(shift)}, "int" ],
	["LEN", "S", sub {length(shift)}, "length" ],
	# Don't use the arg. BASIC passes in
	["RND", "N", sub {rand()}, "{rand()}" ],
	["VAL", "S", sub {0+shift;}, "{0+shift;}"],

	# and String functions...
	['CHR$', "N", 
	    sub {
	        my $a=shift; 
		if ($a>127 || $a<0) {Exit_Error("Arg. to CHR\$ must be < 127")}
		chr($a);
	    }, "chr" 
	],

	['MID$', "SN;N", 
	    sub {
                my ($str, $index, $length) = @_;
                $index--; # BASIC strings index from 1!
                return (defined $length ?
                    substr($str, $index, $length) :
                    substr($str, $index) );
	    }, 
	    join("\n\t",
	        "{", 
	        'my ($str, $index, $length) = @_;',
		'$index--;', 
		'return (defined $length ? ',
		'    substr($str, $index, $length)',
		'    : substr($str, $index) );') 
	    . "\n}" 
	],
	['STR$', "N", sub {'' . shift;}, "{'' . shift;}"],
    );

    # Initialize intrinsic functions
    foreach (@Init) {
	my ($name, $arg_types, $subref, $perl_sub) = @$_;
	my $func = new Language::Basic::Function::Intrinsic ($name);
	# Now set up the Function object with the function definition etc.
	$func->define($arg_types, $subref, $perl_sub);
    }
} # end sub Language::Basic::Function::Intrinsic::initialize

# This sub defines a function, i.e. says what it does with its arguments
sub define {
    # $subref is a sub ref which "translates" the BASIC function into Perl
    # arg_types is a string containing an N or S for each Numeric or String
    # argument the function takes
    # perlsub is a string which is the perl equivalent of the basic function
    my ($self, $arg_types, $subref, $perl_sub) = @_;
    $self->{"subroutine"} = $subref;
    $self->{"arg_types"} = $arg_types;
    $self->{"perl_sub"} = $perl_sub;
} # end sub Language::Basic::Function::Intrinsic::define

sub evaluate {
    # Note that number & type of args has already been checked
    my ($self, @args) = @_;
    # Put this in an eval to find errors?
    return &{$self->{"subroutine"}} (@args);
} # end sub Language::Basic::Function::Intrinsic::evaluate

# output the function name
sub output_perl {
    my $self = shift;
    my $prog = &Language::Basic::Program::current_program;

    # If it's a basic function that translates to an intrinsic function,
    # just return the function
    my $perl_sub = $self->{"perl_sub"};
    return $perl_sub unless $perl_sub =~ /^\{/;

    # Otherwise, it's more complicated
    my $name = $self->{"name"};
    # Use ucfirst(lc) for intrinsic functions so we don't get 
    # messed up with real intrinsic functions
    $name = ucfirst(lc($name));
    $name =~ s/\$$/_str/;
    # It's a BASIC intrinsic function w/ a perl equivalent
    $name .= "_bas";

    # Note that we're going to have to add sub description at the
    # end of the perl script
    $prog->need_sub($name, $perl_sub);

    return $name;
} # end sub Language::Basic::Function::Intrinsic::output_perl

package Language::Basic::Function::Intrinsic::String;
@Language::Basic::Function::Intrinsic::String::ISA = 
    qw(Language::Basic::Function::Intrinsic Language::Basic::Function::String);
package Language::Basic::Function::Intrinsic::Numeric;
@Language::Basic::Function::Intrinsic::Numeric::ISA = 
    qw(Language::Basic::Function::Intrinsic Language::Basic::Function::Numeric);
} # end package Language::Basic::Function::Intrinsic

######################################################################

=head2

Class Language::Basic::Function::Defined

This class handles functions defined by the user in DEF statements.

=cut

#
# Fields:
#     variables - the function parameters. (LB::Variable::Scalar objects)
#     expression - an arithmetic expression. When the function parameters
#         are correctly set, evaluating this expression will yield the
#         value of the function
{
package Language::Basic::Function::Defined;
@Language::Basic::Function::Defined::ISA = qw(Language::Basic::Function);
use Language::Basic::Common;

# This sub declares a function, i.e. says how many arguments it has
sub declare {
    # $arglist is a ref to a list of LB::Variable::Lvalues, which are the
    # arguments to the Function. (E.g., X in DEF FN(X))
    # $exp is an LB::Expression which, when evaluated on the arguments,
    # will implement the function
    my ($self, $arglistref) = @_;
    my $types; # Each arg is S (String) or N (Numeric)

    foreach my $arg (@$arglistref) {
        ref($arg) =~ /(String|Numeric)$/ or die "Error in LBF::Defined::define";
	$types .= substr($1,0,1);
    }
    $self->{"arg_types"} = $types;

    $self->{"arguments"} = $arglistref;
} # end sub Language::Basic::Function::Defined::define

# This sub defines a function, i.e. says what it does with its arguments
# Just involves setting the function's "expression" field.
sub define {
    my ($self, $exp) = @_;
    $self->{"expression"} = $exp;
}

# Actually evaluate the function on its arguments
# Set each parameter (in "variables" field) to the value given in the
# arguments, then evaluate the expression.
# Just in case user has a function FN(X) and uses X elsewhere in the
# program, save the value of X just before we set X based on the argument.
# This is a poor man's version of variable scoping.
sub evaluate {
    # Note that number & type of args has already been checked
    my ($self, @args) = @_;
    Exit_Error("Function is not defined!") unless defined $self->{"expression"};

    my @save_vars;
    foreach (@{$self->{"arguments"}}) {
	my $var = $_->variable;
        my $arg = shift @args;
	push @save_vars, $var->value;
	$var->set($arg);
    }

    my $value = $self->{"expression"}->evaluate;

    # Now restore the values of the function parameters that we may have
    # changed.
    foreach (@{$self->{"arguments"}}) {
	my $var = $_->variable;
        my $save = shift @save_vars;
	$var->set($save);
    }

    return $value;
} # end sub Language::Basic::Function::Defined::evaluate

# output the function name
sub output_perl {
    my $self = shift;
    my $name = $self->{"name"};
    $name = lc($name);
    # First "string", then "function"
    $name =~ s/\$$/_str/;
    $name =~ s/^fn(.*)/$1_fun/;
    return $name;
} # end sub Language::Basic::Function::Defined::output_perl

package Language::Basic::Function::Defined::String;
@Language::Basic::Function::Defined::String::ISA = 
    qw(Language::Basic::Function::Defined Language::Basic::Function::String);
package Language::Basic::Function::Defined::Numeric;
@Language::Basic::Function::Defined::Numeric::ISA = 
    qw(Language::Basic::Function::Defined Language::Basic::Function::Numeric);
} # end package Language::Basic::Function::Defined

{
# set ISA for "return type" classes
package Language::Basic::Function::Numeric;
@Language::Basic::Function::Numeric::ISA = qw
    (Language::Basic::Function Language::Basic::Numeric);
package Language::Basic::Function::String;
@Language::Basic::Function::String::ISA = qw
    (Language::Basic::Function Language::Basic::String);
}
1; # end package Language::Basic::Function
