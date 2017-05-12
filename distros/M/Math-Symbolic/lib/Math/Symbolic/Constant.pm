
=encoding utf8

=head1 NAME

Math::Symbolic::Constant - Constants in symbolic calculations

=head1 SYNOPSIS

  use Math::Symbolic::Constant;
  my $const = Math::Symbolic::Constant->new(25);
  my $zero  = Math::Symbolic::Constant->zero();
  my $one   = Math::Symbolic::Constant->one();
  my $euler = Math::Symbolic::Constant->euler();
  # e = 2.718281828...

=head1 DESCRIPTION

This module implements numeric constants for Math::Symbolic trees.

=head2 EXPORT

None by default.

=cut

package Math::Symbolic::Constant;

use 5.006;
use strict;
use warnings;
use Carp;

use Math::Symbolic::ExportConstants qw/:all/;

use base 'Math::Symbolic::Base';

our $VERSION = '0.612';

=head1 METHODS

=cut

=head2 Constructor new

Takes hash reference of key-value pairs as argument.
Special case: a value for the constant instead of the hash.
Returns a Math::Symbolic::Constant.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my %args;
    %args = %{ shift() } if @_ && ref( $_[0] ) eq 'HASH';

    my $value = ( @_ && !%args ? shift : $args{value} );
    $value = $proto->value() if !defined($value) and ref($proto);

    croak("Math::Symbolic::Constant created with undefined value!")
      if not defined($value);

    my $self = {
        special => '',
        ( ref($proto) ? %$proto : () ),
        value => $value,
        %args,
    };

    bless $self => $class;
}

=head2 Constructor zero

Arguments are treated as key-value pairs of object attributes.
Returns a Math::Symbolic::Constant with value of 0.

=cut

sub zero {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    croak("Uneven number of arguments to zero()") if @_ % 2;

    return(
	    bless {@_, value => 0, special => 'zero' } => $class
	);

#    return $class->new( { @_, value => 0, special => 'zero' } );
}

=head2 Constructor one

Arguments are treated as key-value pairs of object attributes.
Returns a Math::Symbolic::Constant with value of 1.

=cut

sub one {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    croak("Uneven number of arguments to one()") if @_ % 2;

    return(
	    bless {@_, value => 1, special => 'one' } => $class
	);
	
    #return $class->new( { @_, value => 1 } );
}

=head2 Constructor euler

Arguments are treated as key-value pairs of object attributes.
Returns a Math::Symbolic::Constant with value of e, the Euler number.
The object has its 'special' attribute set to 'euler'.

=cut

sub euler {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    croak("Uneven number of arguments to euler()") if @_ % 2;

    return(
	    bless {@_, value => EULER, special => 'euler' } => $class
	);
    
	#return $class->new( { @_, value => EULER, special => 'euler' } );
}

=head2 Constructor pi

Arguments are treated as key-value pairs of object attributes.
Returns a Math::Symbolic::Constant with value of pi.
The object has its 'special' attribute set to 'pi'.

=cut

sub pi {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    croak("Uneven number of arguments to pi()") if @_ % 2;

    return(
	    bless {@_, value => PI, special => 'pi' } => $class
	);
    
	#return $class->new( { @_, value => PI, special => 'pi' } );
}

=head2 Method value

value() evaluates the Math::Symbolic tree to its numeric representation.

value() without arguments requires that every variable in the tree contains
a defined value attribute. Please note that this refers to every variable
I<object>, not just every named variable.

value() with one argument sets the object's value if you're dealing with
Variables or Constants. In case of operators, a call with one argument will
assume that the argument is a hash reference. (see next paragraph)

value() with named arguments (key/value pairs) associates variables in the tree
with the value-arguments if the corresponging key matches the variable name.
(Can one say this any more complicated?) Since version 0.132, an
equivalent and valid syntax is to pass a single hash reference instead of a
list.

Example: $tree->value(x => 1, y => 2, z => 3, t => 0) assigns the value 1 to
any occurrances of variables of the name "x", aso.

If a variable in the tree has no value set (and no argument of value sets
it temporarily), the call to value() returns undef.

=cut

sub value {
    my $self = shift;
    if ( @_ == 1 and not ref( $_[0] ) eq 'HASH' ) {
        croak "Constant assigned undefined value!"
          if not defined $_[0];
        
		$self->{value}   = $_[0];
        $self->{special} = undef;    # !!!FIXME!!! one day, this
                                     # needs better handling.
    }
    return $self->{value};
}

=head2 Method signature

signature() returns a tree's signature.

In the context of Math::Symbolic, signatures are the list of variables
any given tree depends on. That means the tree "v*t+x" depends on the
variables v, t, and x. Thus, applying signature() on the tree that would
be parsed from above example yields the sorted list ('t', 'v', 'x').

Constants do not depend on any variables and therefore return the empty list.
Obviously, operators' dependencies vary.

Math::Symbolic::Variable objects, however, may have a slightly more
involved signature. By convention, Math::Symbolic variables depend on
themselves. That means their signature contains their own name. But they
can also depend on various other variables because variables themselves
can be viewed as placeholders for more compicated terms. For example
in mechanics, the acceleration of a particle depends on its mass and
the sum of all forces acting on it. So the variable 'acceleration' would
have the signature ('acceleration', 'force1', 'force2',..., 'mass', 'time').

If you're just looking for a list of the names of all variables in the tree,
you should use the explicit_signature() method instead.

=cut

sub signature {
    return ();
}

=head2 Method explicit_signature

explicit_signature() returns a lexicographically sorted list of
variable names in the tree.

See also: signature().

=cut

sub explicit_signature {
    return ();
}

=head2 Method special

Optional argument: sets the object's special attribute.
Returns the object's special attribute.

=cut

sub special {
    my $self = shift;
    $self->{special} = shift if @_;
    return $self->{special};
}

=head2 Method to_string

Returns a string representation of the constant.

=cut

sub to_string {
    my $self = shift;
    return $self->value();
}

=head2 Method term_type

Returns the type of the term. (T_CONSTANT)

=cut

sub term_type { T_CONSTANT }

1;
__END__

=head1 AUTHOR

Please send feedback, bug reports, and support requests to the Math::Symbolic
support mailing list:
math-symbolic-support at lists dot sourceforge dot net. Please
consider letting us know how you use Math::Symbolic. Thank you.

If you're interested in helping with the development or extending the
module's functionality, please contact the developers' mailing list:
math-symbolic-develop at lists dot sourceforge dot net.

List of contributors:

  Steffen Müller, symbolic-module at steffen-mueller dot net
  Stray Toaster, mwk at users dot sourceforge dot net
  Oliver Ebenhöh

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN. The module development takes place on
Sourceforge at http://sourceforge.net/projects/math-symbolic/

L<Math::Symbolic>

=cut


