
=encoding utf8

=head1 NAME

Math::Symbolic::Operator - Operators in symbolic calculations

=head1 SYNOPSIS

  use Math::Symbolic::Operator;
  
  my $sum = Math::Symbolic::Operator->new('+', $term1, $term2);
  
  # or:
  my $division =
    Math::Symbolic::Operator->new(
      {
        type     => B_DIVISON,
        operands => [$term1, $term2],
      }
    );
  
  my $derivative =
    Math::Symbolic::Operator->new(
      {
        type     => U_P_DERIVATIVE,
        operands => [$term],
      }
    );

=head1 DESCRIPTION

This module implements all Math::Symbolic::Operator objects.
These objects are overloaded in stringification-context to call the
to_string() method on the object. In numeric and boolean context, they
evaluate to their numerical representation.

For a list of supported operators, please refer to the list found below, in the
documentation for the new() constructor.

Math::Symbolic::Operator inherits from Math::Symbolic::Base.

=head2 EXPORT

None.

=cut

package Math::Symbolic::Operator;

use 5.006;
use strict;
use warnings;
no warnings 'recursion';

use Carp;

use Math::Symbolic::ExportConstants qw/:all/;
use Math::Symbolic::Derivative qw//;

use base 'Math::Symbolic::Base';

our $VERSION = '0.612';

=head1 CLASS DATA

Math::Symbolic::Operator contains several class data structures. Usually, you
should not worry about dealing with any of them because they are mostly an
implementation detail, but for the sake of completeness, here's the gist, but
feel free to skip this section of the docs:

One of these is the %Op_Symbols hash that associates operator (and function)
symbols with the corresponding constant as exported by Math::Symbolic or
Math::Symbolic::ExportConstants. (For example, '+' => B_SUM which in turn is
0, if I recall correctly. But I didn't tell you that. Because you're supposed
to use the supplied (inlined and hence fast) constants so I can change their
internal order if I deem it necessary.)

=cut

our %Op_Symbols = (
    '+'                  => B_SUM,
    '-'                  => B_DIFFERENCE,
    '*'                  => B_PRODUCT,
    '/'                  => B_DIVISION,
    'log'                => B_LOG,
    '^'                  => B_EXP,
    'neg'                => U_MINUS,
    'partial_derivative' => U_P_DERIVATIVE,
    'total_derivative'   => U_T_DERIVATIVE,
    'sin'                => U_SINE,
    'cos'                => U_COSINE,
    'tan'                => U_TANGENT,
    'cot'                => U_COTANGENT,
    'asin'               => U_ARCSINE,
    'acos'               => U_ARCCOSINE,
    'atan'               => U_ARCTANGENT,
    'acot'               => U_ARCCOTANGENT,
    'sinh'               => U_SINE_H,
    'cosh'               => U_COSINE_H,
    'asinh'              => U_AREASINE_H,
    'acosh'              => U_AREACOSINE_H,
    'atan2'              => B_ARCTANGENT_TWO,
);

=pod

The array @Op_Types associates operator indices (recall those nifty constants?)
with anonymous hash datastructures that contain some info on the operator such
as its arity, the rule used to derive it, its infix string, its prefix string,
and information on how to actually apply it to numbers.

=cut

our @Op_Types = (

    # B_SUM
    {
        arity         => 2,
        derive        => 'each operand',
        infix_string  => '+',
        prefix_string => 'add',
        application   => '$_[0] + $_[1]',
        commutative   => 1,
    },

    # B_DIFFERENCE
    {
        arity         => 2,
        derive        => 'each operand',
        infix_string  => '-',
        prefix_string => 'subtract',
        application   => '$_[0] - $_[1]',
        #commutative   => 0,
    },

    # B_PRODUCT
    {
        arity         => 2,
        derive        => 'product rule',
        infix_string  => '*',
        prefix_string => 'multiply',
        application   => '$_[0] * $_[1]',
        commutative   => 1,
    },

    # B_DIVISION
    {
        derive        => 'quotient rule',
        arity         => 2,
        infix_string  => '/',
        prefix_string => 'divide',
        application   => '$_[0] / $_[1]',
        #commutative   => 0,
    },

    # U_MINUS
    {
        arity         => 1,
        derive        => 'each operand',
        infix_string  => '-',
        prefix_string => 'negate',
        application   => '-$_[0]',
    },

    # U_P_DERIVATIVE
    {
        arity         => 2,
        derive        => 'derivative commutation',
        infix_string  => undef,
        prefix_string => 'partial_derivative',
        application   => \&Math::Symbolic::Derivative::partial_derivative,
    },

    # U_T_DERIVATIVE
    {
        arity         => 2,
        derive        => 'derivative commutation',
        infix_string  => undef,
        prefix_string => 'total_derivative',
        application   => \&Math::Symbolic::Derivative::total_derivative,
    },

    # B_EXP
    {
        arity         => 2,
        derive        => 'logarithmic chain rule after ln',
        infix_string  => '^',
        prefix_string => 'exponentiate',
        application   => '$_[0] ** $_[1]',
        #commutative   => 0,
    },

    # B_LOG
    {
        arity         => 2,
        derive        => 'logarithmic chain rule',
        infix_string  => undef,
        prefix_string => 'log',
        application   => 'log($_[1]) / log($_[0])',
        #commutative   => 0,
    },

    # U_SINE
    {
        arity         => 1,
        derive        => 'trigonometric derivatives',
        infix_string  => undef,
        prefix_string => 'sin',
        application   => 'sin($_[0])',
    },

    # U_COSINE
    {
        arity         => 1,
        derive        => 'trigonometric derivatives',
        infix_string  => undef,
        prefix_string => 'cos',
        application   => 'cos($_[0])',
    },

    # U_TANGENT
    {
        arity         => 1,
        derive        => 'trigonometric derivatives',
        infix_string  => undef,
        prefix_string => 'tan',
        application   => 'sin($_[0])/cos($_[0])',
    },

    # U_COTANGENT
    {
        arity         => 1,
        derive        => 'trigonometric derivatives',
        infix_string  => undef,
        prefix_string => 'cot',
        application   => 'cos($_[0])/sin($_[0])',
    },

    # U_ARCSINE
    {
        arity         => 1,
        derive        => 'inverse trigonometric derivatives',
        infix_string  => undef,
        prefix_string => 'asin',
        #application   => 'Math::Symbolic::AuxFunctions::asin($_[0])',
        application   => 'atan2( $_[0], sqrt( 1 - $_[0] * $_[0] ) )',
    },

    # U_ARCCOSINE
    {
        arity         => 1,
        derive        => 'inverse trigonometric derivatives',
        infix_string  => undef,
        prefix_string => 'acos',
        application   => 'atan2( sqrt( 1 - $_[0] * $_[0] ), $_[0] ) ',
        #application   => 'Math::Symbolic::AuxFunctions::acos($_[0])',
    },

    # U_ARCTANGENT
    {
        arity         => 1,
        derive        => 'inverse trigonometric derivatives',
        infix_string  => undef,
        prefix_string => 'atan',
        application   => 'atan2($_[0], 1)',
        #application   => 'Math::Symbolic::AuxFunctions::atan($_[0])',
    },

    # U_ARCCOTANGENT
    {
        arity         => 1,
        derive        => 'inverse trigonometric derivatives',
        infix_string  => undef,
        prefix_string => 'acot',
        application   => 'atan2(1 / $_[0], 1)',
        #application   => 'Math::Symbolic::AuxFunctions::acot($_[0])',
    },

    # U_SINE_H
    {
        arity         => 1,
        derive        => 'trigonometric derivatives',
        infix_string  => undef,
        prefix_string => 'sinh',
        #application   => '0.5*(EULER**$_[0] - EULER**(-$_[0]))',
        application   => '0.5*('.EULER.'**$_[0] - '.EULER.'**(-$_[0]))',
    },

    # U_COSINE_H
    {
        arity         => 1,
        derive        => 'trigonometric derivatives',
        infix_string  => undef,
        prefix_string => 'cosh',
        application   => '0.5*('.EULER.'**$_[0] + '.EULER.'**(-$_[0]))',
        #application   => '0.5*(EULER**$_[0] + EULER**(-$_[0]))',
    },

    # U_AREASINE_H
    {
        arity         => 1,
        derive        => 'inverse trigonometric derivatives',
        infix_string  => undef,
        prefix_string => 'asinh',
        application   => 'log( $_[0] + sqrt( $_[0] * $_[0] + 1 ) ) ',
        #application   => 'Math::Symbolic::AuxFunctions::asinh($_[0])',
    },

    # U_AREACOSINE_H
    {
        arity         => 1,
        derive        => 'inverse trigonometric derivatives',
        infix_string  => undef,
        prefix_string => 'acosh',
        application   => 'log( $_[0] + sqrt( $_[0] * $_[0] - 1 ) ) ',
        #application   => 'Math::Symbolic::AuxFunctions::acosh($_[0])',
    },

    # B_ARCTANGENT_TWO
    {
        arity         => 2,
        derive        => 'inverse atan2',
        infix_string  => undef,
        prefix_string => 'atan2',
        application   => 'atan2($_[0], $_[1])',
        #application   => 'Math::Symbolic::AuxFunctions::atan($_[0])',
        #commutative   => 0,
    },

);

=head1 METHODS

=head2 Constructor new

Expects a hash reference as first argument. That hash's contents
will be treated as key-value pairs of object attributes.
Important attributes are 'type' => OPERATORTYPE (use constants as
exported by Math::Symbolic::ExportConstants!) and 'operands=>[op1,op2,...]'.
Where the operands themselves may either be valid Math::Symbolic::* objects
or strings that will be parsed as such.

Special case: if no hash reference was found, first
argument is assumed to be the operator's symbol and the operator
is assumed to be binary. The following 2 arguments will be treated as
operands. This special case will ignore attempts to clone objects but if
the operands are no valid Math::Symbolic::* objects, they will be sent
through a Math::Symbolic::Parser to construct Math::Symbolic trees.

Returns a Math::Symbolic::Operator.

Supported operator symbols: (number of operands and their
function in parens)

  +                  => sum (2)
  -                  => difference (2)
  *                  => product (2)
  /                  => division (2)
  log                => logarithm (2: base, function)
  ^                  => exponentiation (2: base, exponent)
  neg                => unary minus (1)
  partial_derivative => partial derivative (2: function, var)
  total_derivative   => total derivative (2: function, var)
  sin                => sine (1)
  cos                => cosine (1)
  tan                => tangent (1)
  cot                => cotangent (1)
  asin               => arc sine (1)
  acos               => arc cosine (1)
  atan               => arc tangent (1)
  atan2              => arc tangent of y/x (2: y, x)
  acot               => arc cotangent (1)
  sinh               => hyperbolic sine (1)
  cosh               => hyperbolic cosine (1)
  asinh              => hyperbolic area sine (1)
  acosh              => hyperbolic area cosine (1)

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    if ( @_ and not( ref( $_[0] ) eq 'HASH' ) ) {
        my $symbol = shift;
        my $type   = $Op_Symbols{$symbol};
        croak "Invalid operator type specified ($symbol)."
          unless defined $type;
        my $operands = [ @_[ 0 .. $Op_Types[$type]{arity} - 1 ] ];

        croak "Undefined operands not supported by "
          . "Math::Symbolic::Operator objects."
          if grep +( not defined($_) ), @$operands;

        @$operands =
          map {
            ref($_) =~ /^Math::Symbolic/
              ? $_
              : Math::Symbolic::parse_from_string($_)
          } @$operands;

        return bless {
            type     => $type,
            operands => $operands,
        } => $class;
    }

    my %args;
    %args = %{ $_[0] } if @_;
    # and ref( $_[0] ) eq 'HASH';
    # above condition isn't necessary since that'd otherwise have been
    # the above branch.

    my $operands = [];
    if ( ref $proto ) {
        foreach ( @{ $proto->{operands} } ) {
            push @$operands, $_->new();
        }
    }

    my $self = {
        type => undef,
        ( ref($proto) ? %$proto : () ),
        operands => $operands,
        %args,
    };

    @{ $self->{operands} } =
      map {
        ref($_) =~ /^Math::Symbolic/
          ? $_
          : Math::Symbolic::parse_from_string($_)
      } @{ $self->{operands} };

    bless $self => $class;
}

=head2 Method arity

Returns the operator's arity as an integer.

=cut

sub arity {
    my $self = shift;
    return $Op_Types[ $self->{type} ]{arity};
}

=head2 Method type

Optional integer argument that sets the operator's type.
Returns the operator's type as an integer.

=cut

sub type {
    my $self = shift;
    $self->{type} = shift if @_;
    return $self->{type};
}

=head2 Method to_string

Returns a string representation of the operator and its operands.
Optional argument: 'prefix' or 'infix'. Defaults to 'infix'.

=cut

sub to_string {
    my $self        = shift;
    my $string_type = shift;
    $string_type = 'infix'
      unless defined $string_type
      and $string_type eq 'prefix';
    no warnings 'recursion';

    my $string = '';
    if ( $string_type eq 'prefix' ) {
        $string .= $self->_to_string_prefix();
    }
    else {
        $string .= $self->_to_string_infix();
    }
    return $string;
}

sub _to_string_infix {
    my $self = shift;
    my $op   = $Op_Types[ $self->{type} ];

    my $op_str = $op->{infix_string};
    my $string;
    if ( $op->{arity} == 2 ) {
        my $op1 = $self->{operands}[0]->term_type() == T_OPERATOR;
        my $op2 = $self->{operands}[1]->term_type() == T_OPERATOR;

        if ( not defined $op_str ) {
            $op_str = $op->{prefix_string};
            $string = "$op_str(";
            $string .= join( ', ',
                map { $_->to_string('infix') } @{ $self->{operands} } );
            $string .= ')';
        }
        else {
            $string =
                ( $op1 ? '(' : '' )
              . $self->{operands}[0]->to_string('infix')
              . ( $op1 ? ')' : '' )
              . " $op_str "
              . ( $op2 ? '(' : '' )
              . $self->{operands}[1]->to_string('infix')
              . ( $op2 ? ')' : '' );
        }
    }
    elsif ( $op->{arity} == 1 ) {
        my $is_op1 = $self->{operands}[0]->term_type() == T_OPERATOR;
        if ( not defined $op_str ) {
            $op_str = $op->{prefix_string};
            $string =
              "$op_str(" . $self->{operands}[0]->to_string('infix') . ")";
        }
        else {
            $string = "$op_str"
              . ( $is_op1 ? '(' : '' )
              . $self->{operands}[0]->to_string('infix')
              . ( $is_op1 ? ')' : '' );
        }
    }
    else {
        $string = $self->_to_string_prefix();
    }
    return $string;
}

sub _to_string_prefix {
    my $self = shift;
    my $op   = $Op_Types[ $self->{type} ];

    my $op_str = $op->{prefix_string};
    my $string = "$op_str(";
    $string .=
      join( ', ', map { $_->to_string('prefix') } @{ $self->{operands} } );
    $string .= ')';
    return $string;
}

=head2 Method term_type

Returns the type of the term. ( T_OPERATOR )

=cut

sub term_type {T_OPERATOR}

=head2 Method simplify

Term simpilification.
First argument: Boolean indicating that the tree does not
need to be cloned, but can be restructured instead.
While this is faster, you might not be able to use the old
tree any more.

Example:

  my $othertree = $tree->simplify();
  # can use $othertree and $tree now.

  my $yetanothertree = $tree->simplify(1);
  # must not use $tree any more because its internal
  # representation might have been destroyed.

If you want to optimize a routine and you're sure that you
won't need the unsimplified tree any more, go ahead and use
the first parameter. In all other cases, you should go the
safe route.

=cut

sub simplify {
    my $self = shift;
    my $dont_clone = shift;
    $self = $self->new() unless $dont_clone;

    my $operands = $self->{operands};
    my $op       = $Op_Types[ $self->type() ];

    # simplify operands without cloning.
    @$operands = map { $_->simplify(1) } @$operands;

    if ( $self->arity() == 2 ) {
        my $o1   = $operands->[0];
        my $o2   = $operands->[1];
        my $tt1  = $o1->term_type();
        my $tt2  = $o2->term_type();
        my $type = $self->type();

        if ( $self->is_simple_constant() ) {
            return $self->apply();
        }

        if ( $o1->is_identical($o2) ) {
            if ( $type == B_PRODUCT ) {
                my $two = Math::Symbolic::Constant->new(2);
                return $self->new( '^', $o1, $two )->simplify(1);
            }
            elsif ( $type == B_SUM ) {
                my $two = Math::Symbolic::Constant->new(2);
                return $self->new( '*', $two, $o1 )->simplify(1);
            }
            elsif ( $type == B_DIVISION ) {
                croak "Symbolic division by zero."
                  if $o2->term_type() == T_CONSTANT
                  and ($o2->value() == 0
                    or $o2->special() eq 'zero' );
                return Math::Symbolic::Constant->one();
            }
            elsif ( $type == B_DIFFERENCE ) {
                return Math::Symbolic::Constant->zero();
            }
        }

        # exp(0) = 1
        if (    $tt2 == T_CONSTANT
            and $tt1 == T_OPERATOR
            and $type == B_EXP
            and $o2->value() == 0 )
        {
            return Math::Symbolic::Constant->one();
        }
        
        # a^1 = a
        if ( $tt2 == T_CONSTANT
            and $type == B_EXP
            and ( $o2->value() == 1 or $o2->special() eq 'one' ) )
        {
            return $o1;
        }

        # (a^b)^const = a^(const*b)
        if ( $tt2 == T_CONSTANT
            and $tt1 == T_OPERATOR
            and $type == B_EXP
            and $o1->type() == B_EXP )
        {
            return $self->new( '^', $o1->op1(),
                $self->new( '*', $o2, $o1->op2() ) )->simplify(1);
        }

# redundant
#        if ( $tt1 == T_VARIABLE
#            and $tt2 == T_VARIABLE
#            and $o1->name() eq $o2->name() )
#        {
#            if ( $type == B_SUM ) {
#                my $two = Math::Symbolic::Constant->new(2);
#                return $self->new( '*', $two, $o1 );
#            }
#            elsif ( $type == B_DIFFERENCE ) {
#                return Math::Symbolic::Constant->zero();
#            }
#            elsif ( $type == B_PRODUCT ) {
#                my $two = Math::Symbolic::Constant->new(2);
#                return $self->new( '^', $o1, $two );
#            }
#            elsif ( $type == B_DIVISION ) {
#                return Math::Symbolic::Constant->one();
#            }
#        }

        if ( $tt1 == T_CONSTANT or $tt2 == T_CONSTANT ) {
            my $const = ( $tt1 == T_CONSTANT ? $o1 : $o2 );
            my $not_c = ( $tt1 == T_CONSTANT ? $o2 : $o1 );
            my $constant_first = $tt1 == T_CONSTANT;

            if ( $type == B_SUM ) {
                return $not_c if $const->value() == 0;
                return $not_c->mod_add_constant($const);
            }
            
            if ( $type == B_DIFFERENCE ) {
                if (!$constant_first) {
                    my $value = $const->value();
                    return $not_c if $value == 0;
                    return $not_c->mod_add_constant(-$value);
                }
                if ( $constant_first and $const->value == 0 ) {
                    return Math::Symbolic::Operator->new(
                        {
                            type     => U_MINUS,
                            operands => [$not_c],
                        }
                    );
                }
            }
            
            if ( $type == B_PRODUCT ) {
                return $not_c if $const->value() == 1;
                return Math::Symbolic::Constant->zero()
                  if $const->value == 0;

                if (    $not_c->term_type() == T_OPERATOR
                    and $not_c->type() == B_PRODUCT
                    and $not_c->op1()->term_type() == T_CONSTANT
                    || $not_c->op2()->term_type() == T_CONSTANT )
                {
                    my ( $c, $nc ) = (
                        $not_c->op1()->term_type() == T_CONSTANT
                        ? ( $not_c->op1, $not_c->op2 )
                        : ( $not_c->op2, $not_c->op1 )
                    );
                    my $c_product = $not_c->new( '*', $const, $c )->apply();
                    return $not_c->new( '*', $c_product, $nc );
                }
                elsif ( $not_c->term_type() == T_OPERATOR
                    and $not_c->type() == B_DIVISION
                    and $not_c->op1()->term_type() == T_CONSTANT )
                {
                    return Math::Symbolic::Operator->new(
                        '/',
                        Math::Symbolic::Constant->new(
                            $const->value() * $not_c->op1()->value()
                        ),
                        $not_c->op2()
                    );
                }
            }
            elsif ( $type == B_DIVISION ) {
                return $not_c
                  if !$constant_first
                  and $const->value == 1;
                return Math::Symbolic::Constant->new('#Inf')
                  if !$constant_first
                  and $const->value == 0;
                return Math::Symbolic::Constant->zero()
                  if $const->value == 0;

            }
        }
        elsif ( $type == B_PRODUCT ) {
            if ( $tt2 == T_CONSTANT ) {
                return $o1->mod_multiply_constant($o2);
            }
            elsif ( $tt1 == T_CONSTANT ) {
                return $o2->mod_multiply_constant($o1);
            }
            elsif ( $tt1 == T_OPERATOR and $tt2 == T_VARIABLE ) {
                return $self->new( '*', $o2, $o1 );
            }
        }

        if ( $type == B_SUM ) {
            my @ops;
            my @const;
            my @todo = ( $o1, $o2 );
            my %vars;
            while (@todo) {
                my $this = shift @todo;

                if ( $this->term_type() == T_OPERATOR ) {
                    my $t = $this->type();
                    if ( $t == B_SUM ) {
                        push @todo, @{ $this->{operands} };
                    }
                    elsif ( $t == B_DIFFERENCE ) {
                        push @todo, $this->op1(),
                          Math::Symbolic::Operator->new( 'neg',
                            $this->op2() );
                    }
                    elsif ( $t == U_MINUS ) {
                        my $op = $this->op1();
                        my $tt = $op->term_type();
                        if ( $tt == T_VARIABLE ) {
                            $vars{$op->name}--;
                        }
                        elsif ( $tt == T_CONSTANT ) {
                            push @const, $todo[0]->value();
                        }
                        else {
                            my $ti = $op->type();
                            if ( $ti == U_MINUS ) {
                                push @todo, $op->op1();
                            }
                            elsif ( $ti == B_SUM ) {
                                push @todo,
                                  Math::Symbolic::Operator->new(
                                    'neg', $op->op1()
                                  ),
                                  Math::Symbolic::Operator->new( 'neg',
                                    $op->op2() );
                            }
                            elsif ( $ti == B_DIFFERENCE ) {
                                push @todo, $op->op2(),
                                  Math::Symbolic::Operator->new( 'neg',
                                    $op->op1() );
                            }
                            else {
                                push @ops, $this;
                            }
                        }
                    }
                    elsif ( $t == B_PRODUCT ) {
                        my ($o1, $o2) = @{$this->{operands}};
                        my $tl = $o1->term_type();
                        my $tr = $o2->term_type();
                        
                        if ($tl == T_VARIABLE and $tr == T_CONSTANT) {
                            $vars{$o1->name}+= $o2->value();
                        }
                        elsif ($tr == T_VARIABLE and $tl == T_CONSTANT) {
                            $vars{$o2->name}+= $o1->value();
                        }
                        else {
                            push @ops, $this;
                        }
                    }
                    else {
                        push @ops, $this;
                    }
                }
                elsif ( $this->term_type() == T_VARIABLE ) {
                    $vars{$this->name}++;
                }
                else {
                    push @const, $this->value();
                }
            }

            my @vars = ();
            foreach (keys %vars) {
                my $num  = $vars{$_};
                if (!$num) { next; }
                
                if ($num == 1) {
                    push @vars, Math::Symbolic::Variable->new($_);
                    next;
                }
                my $mul = Math::Symbolic::Operator->new(
                    '*',
                    Math::Symbolic::Constant->new(abs($num)),
                    Math::Symbolic::Variable->new($_)
                );
                push @ops, $num < 0
                    ? Math::Symbolic::Operator->new('neg', $mul)
                    : $mul;                
            }
            
            my $const;
            $const = Math::Symbolic::Constant->new($const) if defined $const and $const != 0;

            $const = shift @vars if not defined $const;
            foreach ( @vars ) {
                $const = Math::Symbolic::Operator->new('+', $const, $_);
            }
            
            @ops = map {$_->simplify(1)} @ops;
            my @newops;
            push @newops, $const if defined $const;
            foreach my $out ( 0 .. $#ops ) {
                next if not defined $ops[$out];
                my $identical = 0;
                foreach my $in ( 0 .. $#ops ) {
                    next if $in == $out or not defined $ops[$in];
                    if ( $ops[$out]->is_identical( $ops[$in] ) ) {
                        $identical++;
                        $ops[$in] = undef;
                    }
                }
                if ( not $identical ) {
                    push @newops, $ops[$out];
                }
                else {
                    push @newops,
                      Math::Symbolic::Operator->new( '*', $identical + 1,
                        $ops[$out] );
                }
            }
            
            my $sumops;
            if (@newops) {
                $sumops = shift @newops;
                $sumops += $_ foreach @newops;
            }
            else {return Math::Symbolic::Constant->zero()}

            return $sumops;
        }
    }
    elsif ( $self->arity() == 1 ) {
        my $o    = $operands->[0];
        my $tt   = $o->term_type();
        my $type = $self->type();
        if ( $type == U_MINUS ) {
            if ( $tt == T_CONSTANT ) {
                return Math::Symbolic::Constant->new( -$o->value(), );
            }
            elsif ( $tt == T_OPERATOR ) {
                my $inner_type = $o->type();
                if ( $inner_type == U_MINUS ) {
                    return $o->{operands}[0];
                }
                elsif ( $inner_type == B_DIFFERENCE ) {
                    return $o->new( '-', @{$o->{operands}}[1,0] );
                }
            }
        }
    }

    return $self;
}

=head2 Methods op1 and op2

Returns first/second operand of the operator if it exists or undef.

=cut

sub op1 {
    return $_[0]{operands}[0] if @{ $_[0]{operands} } >= 1;
    return undef;
}

sub op2 {
    return $_[0]{operands}[1] if @{ $_[0]{operands} } >= 2;
}

=head2 Method apply

Applies the operation to its operands' value() and returns the result
as a constant (-object).

Without arguments, all variables in the tree are required to have a value.
If any don't, the call to apply() returns undef.

To (temorarily, for this single method call) assign values to
variables in the tree, you may provide key/value pairs of variable names
and values. Instead of passing a list of key/value pairs, you may also pass
a single hash reference containing the variable mappings.

You usually want to call the value() instead of this.

=cut

sub apply {
    my $self        = shift;
    my $args        = ( @_ == 1 ? $_[0] : +{ @_ } );
    my $op_type     = $self->type();
    my $op          = $Op_Types[$op_type];
    my $operands    = $self->{operands};
    my $application = $op->{application};

    if ( ref($application) ne 'CODE' ) {
        local @_;
        local $@;
        eval {
            @_ = map {
                my $v = $_->value($args);
                (
                    defined $v
                    ? $v
                    : croak 
                      "Undefined operand in Math::Symbolic::Operator->apply()"
                  )
            } @$operands;
        };
        return undef if $@;
        return undef if $op_type == B_DIVISION and $_[1] == 0;
        my $result = eval $application;
        die "Invalid operator application: $@" if $@;
        die "Undefined result from operator application."
          if not defined $result;

        return Math::Symbolic::Constant->new($result);
    }
    else {
        return $application->(@$operands);
    }
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
    my $args = ( @_ == 1 ? $_[0] : +{@_} );

    my $applied = $self->apply($args);
    return undef unless defined $applied;
    return $applied->value($args);
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
    my %sig;
    foreach my $o ( $self->descending_operands('all_vars') ) {
        $sig{$_} = undef for $o->signature();
    }
    return sort keys %sig;
}

=head2 Method explicit_signature

explicit_signature() returns a lexicographically sorted list of
variable names in the tree.

See also: signature().

=cut

sub explicit_signature {
    my $self = shift;
    my %sig;
    foreach my $o ( $self->descending_operands('all_vars') ) {
        $sig{$_} = undef for $o->explicit_signature();
    }
    return sort keys %sig;
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



