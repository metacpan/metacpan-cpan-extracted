
=encoding utf8

=head1 NAME

Math::Symbolic::Base - Base class for symbols in symbolic calculations

=head1 SYNOPSIS

  use Math::Symbolic::Base;

=head1 DESCRIPTION

This is a base class for all Math::Symbolic::* terms such as
Math::Symbolic::Operator, Math::Symbolic::Variable and
Math::Symbolic::Constant objects.

=head2 EXPORT

None by default.

=cut

package Math::Symbolic::Base;

use 5.006;
use strict;
use warnings;
no warnings 'recursion';

use Carp;

use overload
  "+"    => \&_overload_addition,
  "-"    => \&_overload_subtraction,
  "*"    => \&_overload_multiplication,
  "/"    => \&_overload_division,
  "**"   => \&_overload_exponentiation,
  "sqrt" => \&_overload_sqrt,
  "log"  => \&_overload_log,
  "exp"  => \&_overload_exp,
  "sin"  => \&_overload_sin,
  "cos"  => \&_overload_cos,
  '""'   => sub { $_[0]->to_string() },
  "0+"   => sub { $_[0]->value() },
  "bool" => sub { $_[0]->value() };

use Math::Symbolic::ExportConstants qw/:all/;

our $VERSION = '0.612';
our $AUTOLOAD;

=head1 METHODS

=cut

=head2 Method to_string

Default method for stringification just returns the object's value.

=cut

sub to_string {
    my $self = shift;
    return $self->value();
}

=head2 Method value

value() evaluates the Math::Symbolic tree to its numeric representation.

value() without arguments requires that every variable in the tree contains
a defined value attribute. Please note that this refers to every variable
I<object>, not just every named variable.

value() with one argument sets the object's value (in case of a variable or
constant).

value() with named arguments (key/value pairs) associates variables in the tree
with the value-arguments if the corresponging key matches the variable name.
(Can one say this any more complicated?) Since version 0.132, an alternative
syntax is to pass a single hash reference.

Example: $tree->value(x => 1, y => 2, z => 3, t => 0) assigns the value 1 to
any occurrances of variables of the name "x", aso.

If a variable in the tree has no value set (and no argument of value sets
it temporarily), the call to value() returns undef.

=cut

sub value {
    croak "This is a method stub from Math::Symbolic::Base. Implement me.";
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
    croak "signature() implemented in the inheriting classes.";
}

=head2 Method explicit_signature

explicit_signature() returns a lexicographically sorted list of
variable names in the tree.

See also: signature().

=cut

sub explicit_signature {
    croak "explicit_signature() implemented in the inheriting classes.";
}

=head2 Method set_signature

set_signature expects any number of variable identifiers as arguments.
It sets a variable's signature to this list of identifiers.

=cut

sub set_signature {
    croak "Cannot set signature of non-Variable Math::Symbolic tree element.";
}

=head2 Method implement

implement() works in-place!

Takes key/value pairs as arguments. The keys are to be variable names
and the values must be valid Math::Symbolic trees. All occurrances
of the variables will be replaced with their implementation.

=cut

sub implement {
    my $self = shift;
    my %args = @_;

    return $self->descend(
        in_place => 1,
        after    => sub {
            my $tree  = shift;
            my $ttype = $tree->term_type();
            if ( $ttype == T_VARIABLE ) {
                my $name = $tree->name();
                if ( exists $args{$name}
                    and defined $args{$name} )
                {
                    $args{$name} =
                      Math::Symbolic::parse_from_string( $args{$name} )
                      unless ref( $args{$name} );
                    $tree->replace( $args{$name} );
                }
            }
            elsif ( $ttype == T_OPERATOR or $ttype == T_CONSTANT ) {
            }
            else {
                croak "'implement' called on invalid term " . "type.";
            }
        },
        operand_finder => sub {
            return $_[0]->descending_operands('all_vars');
        },
    );
}

=head2 Method replace

First argument must be a valid Math::Symbolic tree.

replace() modifies the object it is called on in-place in that it
replaces it with its first argument. Doing that, it retains the original
object reference. This destroys the object it is called on.

However, this also means that you can create recursive trees of objects if
the new tree is to contain the old tree. So make sure you clone the old tree
using the new() method before using it in the replacement tree or you will
end up with a program that eats your memory fast.

=cut

sub replace {
    my $tree = shift;
    my $new  = shift;
    %$tree = %$new;
    bless $tree => ref $new;
    return $tree;
}

=head2 fill_in_vars

This method returns a modified copy of the tree it was called on.

It walks the tree and replaces all variables whose value attribute is
defined (either done at the time of object creation or using set_value())
with the corresponding constant objects. Variables whose value is
not defined are unaffected. Take, for example, the following code:

  $tree = parse_from_string('a*b+a*c');
  $tree->set_value(a => 4, c => 10); # value of b still not defined.
  print $tree->fill_in_vars();
  # prints "(4 * b) + (4 * 10)"

=cut

sub fill_in_vars {
    my $self = shift;
    return $self->descend(
        in_place => 0,
        before   => sub {
            my $term = shift;
            if ( $term->term_type() == T_VARIABLE and defined $term->{value} )
            {
                $term->replace(
                    Math::Symbolic::Constant->new( $term->{value} ) );
            }
            return ();
        },
    );
}

=head2 Method simplify

Minimum method for term simpilification just clones.

=cut

sub simplify {
    my $self = shift;
    return $self->new();
}

=head2 Method descending_operands

When called on an operator, descending_operands tries hard to determine
which operands to descend into. (Which usually means all operands.)
A list of these is returned.

When called on a constant or a variable, it returns the empty list.

Of course, some routines may have to descend into different branches of the
Math::Symbolic tree, but this routine returns the default operands.

The first argument to this method may control its behaviour. If it is any of
the following key-words, behaviour is modified accordingly:

  default   -- obvious. Use default heuristics.
  
  These are all supersets of 'default':
  all       -- returns ALL operands. Use with caution.
  all_vars  -- returns all operands that may contain vars.

=cut

sub descending_operands {
    my $tree  = shift;
    my $ttype = $tree->term_type();

    if ( $ttype == T_CONSTANT or $ttype == T_VARIABLE ) {
        return ();
    }
    elsif ( $ttype == T_OPERATOR ) {
        my $action = shift || 'default';
        my $type   = $tree->type();

        if ( $action eq 'all' ) {
            return @{ $tree->{operands} };
        }
        elsif ( $action eq 'all_vars' ) {
            return @{ $tree->{operands} };
        }
        else {    # default
            if (   $type == U_P_DERIVATIVE
                or $type == U_T_DERIVATIVE )
            {
                return $tree->{operands}[0];
            }
            else {
                return @{ $tree->{operands} };
            }
        }
    }
    else {
        croak "'descending_operands' called on invalid term type.";
    }
    die "Sanity check in 'descending_operands'. Should not be reached.";
}

=head2 Method descend

The method takes named arguments (key/value pairs).
descend() descends (Who would have guessed?) into the Math::Symbolic tree
recursively and for each node, it calls code references with a copy of
the current node as argument. The copy may be modified and will be used for
construction of the returned tree. The automatic copying behaviour may be
turned off.

Returns a (modified) copy of the original tree. If in-place modification is
turned on, the returned tree will not be a copy.

Available parameters are:

=over 2

=item before

A code reference to be used as a callback that will be invoked before descent.
Depending on whether or not the "in_place" option is set, the callback will
be passed a copy of the current node (default) or the original node itself.

The callback may modify the tree node and the modified node will be used to
construct descend()'s return value.

The return value of this callback describes the way descend() handles the
descent into the current node's operands.

If it returns the empty list, the (possibly modified) copy of the current
that was passed to the callback is used as the return value of descend(),
but the recursive descent is continued for all of the current node's operands
which may or may not be modified by the callback. The "after" callback will
be called on the node after descent into the operands. (This is the
normal behavior.)

If the callback returns undef, the descent is stopped for the current branch
and an exact copy of the current branch's children will be used for
descend()'s return value. The "after" callback will be called immediately.

If the callback returns a list of integers, these numbers are assumed to
be the indexes of the current node's operands that are to be descended into.
That means if the callback returns (1), descend will be called for the
second operand and only the second. All other children/operands will be cloned.
As usual, the "after" callback will be called after descent.

Any other return lists will lead to hard-to-debug errors. Tough luck.

Returning a hash reference from the callback allows for complete control
over the descend() routine. The hash may contain the following elements:

=over 2

=item operands

This is a referenced array that will be put in place of the previous
operands. It is the callback's job to make sure the number of operands stays
correct. The "operands" entry is evaluated I<before> the "descend_into"
entry.

=item descend_into

This is a referenced array of integers and references. The integers are
assumed to be indices of the array of operands. Returning (1) results in
descent into the second operand and only the second.

References are assumed to be operands to descend into. descend() will be
directly called on them.

If the array is empty, descend() will act just as if
an empty list had been returned.

=item in_place

Boolean indicating whether or not to modify the operands in-place or not.
If this is true, descend() will be called with the "in_place => 1" parameter.
If false, it will be called with "in_place => 0" instead.
Defaults to false. (Cloning)

This does not affect the call to the "after" callback but only the descent
into operands.

=item skip_after

If this option exists and is set to true, the "after" callback will not be
invoked. This only applies to the current node, not to its children/operands.

=back

The list of options may grow in future versions.

=item after

This is a code reference which will be invoked as a callback after the descent
into the operands.

=item in_place

Controls whether or not to modify the current tree node in-place. Defaults to
false - cloning.

=item operand_finder

This option controls how the descend routine chooses which operands to
recurse into by default. That means it controls which operands descend()
recurses into if the 'before' routine returned the empty list or if
no 'before' routine was specified.

The option may either be a code reference or a string. If it is a code
reference, this code reference will be called with the current node as
argument. If it is a string, the method with that name will be called
on the current node object.

By default, descend() calls the 'descending_operands()' method on the current
node to determine the operands to descend into.

=back

=cut

sub descend {
    my ( $tree, %args ) = @_;
    $tree = $tree->new()
      unless exists $args{in_place}
      and $args{in_place};

    my @opt;

    # Will be used at several locations inside this routine.
    my $operand_finder = sub {
        if ( exists $args{operand_finder} ) {
            my $op_f = $args{operand_finder};
            return $tree->$op_f() if not ref $op_f;
            croak "Invalid 'operand_finder' option passed to "
              . "descend() routine."
              if not ref($op_f) eq 'CODE';
            return $op_f->($tree);
        }
        else {
            return $tree->descending_operands();
        }
    };

    if ( exists $args{before} ) {
        croak "'before' parameter to descend() must be code reference."
          unless ref( $args{before} ) eq 'CODE';
        @opt = $args{before}->($tree);
    }
    if ( exists $args{after} and ref( $args{after} ) ne 'CODE' ) {
        croak "'after' parameter to descend() must be code reference.";
    }

    my $has_control = ( @opt == 1 && ref( $opt[0] ) eq 'HASH' ? 1 : 0 );

    my $ttype = $tree->term_type();

    # Do nothing!
    if ( $ttype != T_OPERATOR ) { }

    # Fine control!
    elsif ($has_control) {
        my $opt      = $opt[0];
        my %new_args = %args;
        $new_args{in_place} = $opt->{in_place}
          if exists $opt->{in_place};

        if ( exists $opt->{operands} ) {
            croak "'operands' return value of 'begin' callback\n"
              . "in descend() must be array reference."
              unless ref( $opt->{operands} ) eq 'ARRAY';

            $tree->{operands} = $opt->{operands};
        }

        if ( exists $opt->{descend_into} ) {
            croak "'descend_into' return value of 'begin'\n"
              . "callback in descend() must be array reference."
              unless ref( $opt->{descend_into} ) eq 'ARRAY';

            $opt->{descend_into} = [ $operand_finder->() ]
              if @{ $opt->{descend_into} } == 0;

            foreach ( @{ $opt->{descend_into} } ) {
                if ( ref $_ ) {
                    $_->replace( $_->descend(%new_args) );
                }
                else {
                    $tree->{operands}[$_] =
                      $tree->{operands}[$_]->descend(%new_args);
                }
            }
        }
    }

    # descend into all operands.
    elsif ( @opt == 0 ) {
        foreach ( $operand_finder->() ) {
            $_->replace( $_->descend(%args) );
        }
    }

    # Do nothing.
    elsif ( @opt == 1 and not defined( $opt[0] ) ) {
    }

    # Descend into indexed operands
    elsif ( @opt >= 1 and not grep { $_ !~ /^[+-]?\d+$/ } @opt ) {
        foreach (@opt) {
            $tree->{operands}[$_] = $tree->{operands}[$_]->descend(%args);
        }
    }

    # Error!
    else {
        croak "Invalid return list from descend() 'before' callback.";
    }

    # skip the after callback?
    if (
        exists $args{after}
        and not($has_control
            and exists $opt[0]{skip_after}
            and $opt[0]{skip_after} )
      )
    {
        $args{after}->($tree);
    }

    return $tree;
}

=head2 Method term_type

Returns the type of the term. This is a stub to be overridden.

=cut

sub term_type {
    croak "term_type not defined for " . __PACKAGE__;
}

=head2 Method set_value

set_value() returns the tree it modifies, but acts in-place on the
Math::Symbolic tree it was called on.

set_value() requires named arguments (key/value pairs) that associate
variable names of variables in the tree with the value-arguments if the
corresponging key matches the variable name.
(Can one say this any more complicated?) Since version 0.132, an alternative
syntax is to pass a single hash reference to the method.

Example: $tree->set_value(x => 1, y => 2, z => 3, t => 0) assigns the value 1
to any occurrances of variables of the name "x", aso.

As opposed to value(), set_value() assigns to the variables I<permanently>
and does not evaluate the tree.

When called on constants, set_value() sets their value to its first
argument, but only if there is only one argument.

=cut

sub set_value {
    my ( $self, %args );
    if ( @_ == 1 ) {
		return();
    }
    elsif ( @_ == 2 ) {
        $self = shift;
        croak "Invalid arguments to method set_value()"
          unless ref $_[0] eq 'HASH';
        %args = %{ $_[0] };
    }
    else {
        ( $self, %args ) = @_;
    }

    my $ttype = $self->term_type();
    if ( $ttype == T_CONSTANT ) {
        return $self unless @_ == 2;
        my $value = $_[1];
        $self->{value} = $value if defined $value;
        return $self;
    }

    $self->descend(
        in_place => 1,
        after    => sub {
            my $tree  = shift;
            my $ttype = $tree->term_type();
            if ( $ttype == T_OPERATOR or $ttype == T_CONSTANT ) {
            }
            elsif ( $ttype == T_VARIABLE ) {
                $tree->{value} = $args{ $tree->{name} }
                  if exists $args{ $tree->{name} };
            }
            else {
                croak "'set_value' called on invalid term " . "type.";
            }
        },
    );

    return $self;
}

=begin comment

Since version 0.102, there are several overloaded operators. The overloaded
interface is documented below. For more info, please have a look at the
Math::Symbolic man page.

=end comment

=cut

sub _overload_make_object {
    my $operand = shift;
    unless ( ref($operand) =~ /^Math::Symbolic/ ) {
        if ( not defined $operand ) {
            return $operand;
        }
        elsif ( $operand !~ /^\s*\d+\s*$/ ) {
            $operand = Math::Symbolic::parse_from_string($operand);
        }
        else {
            $operand = Math::Symbolic::Constant->new($operand);
        }
    }
    return $operand;
}

sub _overload_addition {
    my ( $obj, $operand, $reverse ) = @_;
    $operand = _overload_make_object($operand);
    return $obj if not defined $operand and $reverse;
    ( $obj, $operand ) = ( $operand, $obj ) if $reverse;
    my $n_obj = Math::Symbolic::Operator->new( '+', $obj, $operand );
    return $n_obj;
}

sub _overload_subtraction {
    my ( $obj, $operand, $reverse ) = @_;
    $operand = _overload_make_object($operand);
    return Math::Symbolic::Operator->new( 'neg', $obj )
      if not defined $operand
      and $reverse;
    ( $obj, $operand ) = ( $operand, $obj ) if $reverse;
    my $n_obj = Math::Symbolic::Operator->new( '-', $obj, $operand );
    return $n_obj;
}

sub _overload_multiplication {
    my ( $obj, $operand, $reverse ) = @_;
    $operand = _overload_make_object($operand);
    ( $obj, $operand ) = ( $operand, $obj ) if $reverse;
    my $n_obj = Math::Symbolic::Operator->new( '*', $obj, $operand );
    return $n_obj;
}

sub _overload_division {
    my ( $obj, $operand, $reverse ) = @_;
    $operand = _overload_make_object($operand);
    ( $obj, $operand ) = ( $operand, $obj ) if $reverse;
    my $n_obj = Math::Symbolic::Operator->new( '/', $obj, $operand );
    return $n_obj;
}

sub _overload_exponentiation {
    my ( $obj, $operand, $reverse ) = @_;
    $operand = _overload_make_object($operand);
    ( $obj, $operand ) = ( $operand, $obj ) if $reverse;
    my $n_obj = Math::Symbolic::Operator->new( '^', $obj, $operand );
    return $n_obj;
}

sub _overload_sqrt {
    my ( $obj, undef, $reverse ) = @_;
    my $n_obj =
      Math::Symbolic::Operator->new( '^', $obj,
        Math::Symbolic::Constant->new(0.5) );
    return $n_obj;
}

sub _overload_exp {
    my ( $obj, undef, $reverse ) = @_;
    my $n_obj =
      Math::Symbolic::Operator->new( '^', Math::Symbolic::Constant->euler(),
        $obj, );
    return $n_obj;
}

sub _overload_log {
    my ( $obj, undef, $reverse ) = @_;
    my $n_obj =
      Math::Symbolic::Operator->new( 'log', Math::Symbolic::Constant->euler(),
        $obj, );
    return $n_obj;
}

sub _overload_sin {
    my ( $obj, undef, $reverse ) = @_;
    my $n_obj = Math::Symbolic::Operator->new( 'sin', $obj );
    return $n_obj;
}

sub _overload_cos {
    my ( $obj, undef, $reverse ) = @_;
    my $n_obj = Math::Symbolic::Operator->new( 'cos', $obj );
    return $n_obj;
}

=begin comment

The following AUTOLOAD mechanism delegates all method calls that aren't found
in the normal Math::Symbolic inheritance tree and that start with
'is_', 'test_', 'contains_', 'apply_', 'mod_', or 'to_' to the
Math::Symbolic::Custom class.

The 'is_' and 'test_' "namespaces" are intended for methods that test a
tree on whether or not it has certain characteristics that define a group.
Eg.: 'is_polynomial'

The 'contains_' prefix is intended for tests as well.

The 'apply_' and 'mod_' prefixes are intended for modifications to the tree
itself. Eg.: 'apply_derivatives'

The 'to_' prefix is intended for output / conversion related routines.

=end comment

=cut

sub AUTOLOAD {
    my $call = $AUTOLOAD;
    $call =~ s/.*\:\:(\w+)$/$1/;
    if ( $call =~ /^((?:apply|mod|is|test|contains|to)_\w+)/ ) {
        my $method = $1;
        my $ref    = Math::Symbolic::Custom->can($method);
        if ( defined $ref ) {
            goto &$ref;
        }
        else {
			my $obj = $_[0];
			my $class = ref $obj;
            croak "Invalid method '$call' called on Math::Symbolic "
			."tree. Tree was of type '$class'";
        }
    }
    else {
        my $obj = $_[0];
        my $class = ref $obj;
        croak "Invalid method '$call' called on Math::Symbolic "
        ."tree. Tree was of type '$class'";
    }
}

=begin comment

We override the UNIVERSAL::can routine to reflect method delegations.

=end comment

=cut

sub can {
    my $obj    = shift;
    my $method = shift;

    my $sub = $obj->SUPER::can($method);
    return $sub if defined $sub;

    return Math::Symbolic::Custom->can($method);
}

# to make AUTOLOAD happy: (because it would otherwise try to delegate DESTROY)
sub DESTROY { }

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

