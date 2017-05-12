
=encoding utf8

=head1 NAME

Math::Symbolic::Variable - Variable in symbolic calculations

=head1 SYNOPSIS

  use Math::Symbolic::Variable;

  my $var1 = Math::Symbolic::Variable->new('name');
  $var1->value(5);
  
  my $var2 = Math::Symbolic::Variable->new('x', 2);

  my $var3 =
    Math::Symbolic::Variable->new(
      {
        name  => 'variable',
        value => 1,
      }
    );

=head1 DESCRIPTION

This class implements variables for Math::Symbolic trees.
The objects are overloaded in stringification context to
return their names.

=head2 EXPORT

None by default.

=cut

package Math::Symbolic::Variable;

use 5.006;
use strict;
use warnings;

use Math::Symbolic::ExportConstants qw/:all/;

use base 'Math::Symbolic::Base';

our $VERSION = '0.612';

=head1 METHODS

=head2 Constructor new

First argument is expected to be a hash reference of key-value
pairs which will be used as object attributes.

In particular, a variable is required to have a 'name'. Optional
arguments include a 'value', and a 'signature'. The value expected
for the signature key is a reference to an array of identifiers.

Special case: First argument is not a hash reference. In this
case, first argument is treated as variable name, second as value.
This special case disallows cloning of objects (when used as
object method).

Returns a Math::Symbolic::Variable.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    if (    @_ == 1
        and ref( $_[0] ) eq 'Math::Symbolic::Variable' )
    {
        return $_[0]->new();
    }
    elsif ( @_ and not ref( $_[0] ) eq 'HASH' ) {
        my $name  = shift;
        my $value = shift;
        return
          bless { name => $name, value => $value, signature => [@_] } => $class;
    }


    my $self = {
        value     => undef,
        name      => undef,
        signature => [],
        ( ref($proto) ? %$proto : () ),
        ((@_ and ref($_[0]) eq 'HASH') ? %{$_[0]} : ()),
    };

    bless $self => $class;
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
    if ( @_ == 0 ) {
        return $self->{value};
    }
    elsif ( @_ == 1 and not ref( $_[0] ) eq 'HASH' ) {
        $self->{value} = shift;
        return $self->{value};
    }
    else {
        my $args = ( @_ == 1 ? $_[0] : +{@_} );
        if ( exists $args->{ $self->{name} } ) {
            return $args->{ $self->{name} };
        }
        else {
            return $self->{value};
        }
    }
    die "Sanity check in Math::Symbolic::Variable::value()";
}

=head2 Method name

Optional argument: sets the object's name.
Returns the object's name.

=cut

sub name {
    my $self = shift;
    $self->{name} = shift if @_;
    return $self->{name};
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
    my $self = shift;
    my $sig  = [ @{ $self->{signature} } ];    # copying it
    push @$sig, $self->{name};

    # Make things unique, then sort and return.
    return sort keys %{ { map { ( $_, undef ) } @$sig } };
}

=head2 Method explicit_signature

explicit_signature() returns a lexicographically sorted list of
variable names in the tree.

See also: signature().

=cut

sub explicit_signature {
    return $_[0]->{name};
}

=head2 Method set_signature

set_signature expects any number of variable identifiers as arguments.
It sets a variable's signature to this list of identifiers.

=cut

sub set_signature {
    my $self = shift;
    @{ $self->{signature} } = @_;
    return ();
}

=head2 Method to_string

Returns a string representation of the variable.

=cut

sub to_string {
    my $self = shift;
    return $self->name();
}

=head2 Method term_type

Returns the type of the term. (T_VARIABLE)

=cut

sub term_type {
    return T_VARIABLE;
}

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

