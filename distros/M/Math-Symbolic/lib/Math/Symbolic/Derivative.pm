
=encoding utf8

=head1 NAME

Math::Symbolic::Derivative - Derive Math::Symbolic trees

=head1 SYNOPSIS

  use Math::Symbolic::Derivative qw/:all/;
  $derived = partial_derivative($term, $variable);
  # or:
  $derived = total_derivative($term, $variable);

=head1 DESCRIPTION

This module implements derivatives for Math::Symbolic trees.
Derivatives are Math::Symbolic::Operators, but their implementation
is drawn from this module because it is significantly more complex
than the implementation of most operators.

Derivatives come in two flavours. There are partial- and total derivatives.

Explaining the precise difference between partial- and total derivatives is
beyond the scope of this document, but in the context of Math::Symbolic,
the difference is simply that partial derivatives just derive in terms of
I<explicit> dependency on the differential variable while total derivatives
recongnize implicit dependencies from variable signatures.

Partial derivatives are faster, have been tested more thoroughly, and
are probably what you want for simpler applications anyway.

=head2 EXPORT

None by default. But you may choose to import the total_derivative()
and partial_derivative() functions.

=cut

package Math::Symbolic::Derivative;

use 5.006;
use strict;
use warnings;
no warnings 'recursion';

use Carp;

use Math::Symbolic::ExportConstants qw/:all/;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(
          &total_derivative
          &partial_derivative
          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.612';

=head1  CLASS DATA

The package variable %Partial_Rules contains partial
derivative rules as key-value pairs of names and subroutines.

=cut

# lookup-table for derivative rules for various operators.
our %Rules = (
    'each operand'                      => \&_each_operand,
    'product rule'                      => \&_product_rule,
    'quotient rule'                     => \&_quotient_rule,
    'logarithmic chain rule after ln'   => \&_logarithmic_chain_rule_after_ln,
    'logarithmic chain rule'            => \&_logarithmic_chain_rule,
    'derivative commutation'            => \&_derivative_commutation,
    'trigonometric derivatives'         => \&_trigonometric_derivatives,
    'inverse trigonometric derivatives' => \&_inverse_trigonometric_derivatives,
    'inverse atan2'                     => \&_inverse_atan2,
);

# References to derivative subroutines
# Will be assigned a reference after subroutine compilation.
our $Partial_Sub;
our $Total_Sub;

our @Constant_Simplify = (
    # B_SUM
    sub {
        my $tree = shift;
        my ($op1, $op2) = @{$tree->{operands}};
        my ($t1, $t2) = ($op1->term_type(), $op2->term_type());
        if ($t1 == T_CONSTANT) {
            return $op2 if $op1->{value} == 0;
            if ($t2 == T_CONSTANT) {
                return Math::Symbolic::Constant->new($op1->{value} + $op2->{value});
            }
        }
        elsif ($t2 == T_CONSTANT) {
            return $op1 if $op2->{value} == 0;
        }

        return $tree;
    },

    # B_DIFFERENCE
    sub {
        my $tree = shift;
        my ($op1, $op2) = @{$tree->{operands}};
        my ($t1, $t2) = ($op1->term_type(), $op2->term_type());
        if ($t1 == T_CONSTANT) {
            $op2 *= -1, return $op2 if $op1->{value} == 0;
            if ($t2 == T_CONSTANT) {
                return Math::Symbolic::Constant->new($op1->{value} - $op2->{value});
            }
        }
        elsif ($t2 == T_CONSTANT) {
            return $op1 if $op2->{value} == 0;
            $op2->{value} *= -1;
            return Math::Symbolic::Operator->new('+', $op1, $op2);
        }
        return $tree;
    },
    
    # B_PRODUCT
    undef, # implemented inline
    # B_DIVISION
    undef, # not implemented

    # U_MINUS
    sub {
        my $tree = shift;
        my $op = $tree->{operands}[0];
        if ($op->term_type == T_CONSTANT) {
            return Math::Symbolic::Constant->new(-$op->{value});
        }
        return $tree;
    },

    #... not implemented
);

=begin comment

The following subroutines are helper subroutines that apply a
specific rule to a tree.

=end comment

=cut

sub _each_operand {
    my ( $tree, $var, $cloned, $d_sub ) = @_;
    foreach ( @{ $tree->{operands} } ) {
        $_ = $d_sub->( $_, $var, 1 );
    }

    my $type = $tree->type();
    my $simplifier = $Constant_Simplify[$type];
    return $simplifier->($tree) if $simplifier;

    return $tree;
}


sub _product_rule {
    my ( $tree, $var, $cloned, $d_sub ) = @_;
    my $ops = $tree->{operands};
    my ($o1, $o2) = @$ops;
    my ($to1, $to2) = ($o1->term_type(), $o2->term_type());

    # one of the terms is a constant, don't derive it
    if ($to1 == T_CONSTANT) {
        return Math::Symbolic::Constant->zero() if $o1->{value} == 0;
        my $deriv = $d_sub->( $o2, $var, 0 );
        return $deriv if $o1->{value} == 0;
        return Math::Symbolic::Constant->new($deriv->{value}*$o1->{value})
          if $deriv->term_type == T_CONSTANT;
    }
    if ($to2 == T_CONSTANT) {
        return Math::Symbolic::Constant->zero() if $o2->{value} == 0;
        my $deriv = $d_sub->( $o1, $var, 0 );
        return $deriv if $o2->{value} == 0;
        return Math::Symbolic::Constant->new($deriv->{value}*$o2->{value})
          if $deriv->term_type == T_CONSTANT;
    }
    
    my $do1 = $d_sub->( $o1, $var, 0 );
    my $do2 = $d_sub->( $o2, $var, 0 );

    my ($tdo1, $tdo2) = ($do1->term_type(), $do2->term_type());

    my ($m1, $m2);
    # check for const*const
    if ($tdo1 == T_CONSTANT) {
        if ($to2 == T_CONSTANT) {
            $m1 = $do1->new($o2->{value} * $do1->{value}); # const
        } elsif ($do1->{value} == 0) {
            $m1 = $do1->zero(); # 0
        } elsif ($do1->{value} == 1) {
            $m1 = $o2;
        } else {
            $m1 = $do1*$o2; # c*tree
        }
    }
    else {
        $m1 = $o2*$do1;
    }

    if ($tdo2 == T_CONSTANT) {
        if ($to1 == T_CONSTANT) {
            $m2 = $do2->new($o1->{value} * $do2->{value}); # const
        } elsif ($do2->{value} == 0) {
            $m2 = $do2->zero(); # 0
        } elsif ($do2->{value} == 1) {
            $m2 = $o1;
        } else {
            $m2 = $do2*$o1; # c*tree
        }
    }
    else {
        $m2 = $o1*$do2;
    }

    # 0's or 2 consts in +
    if ($m1->term_type == T_CONSTANT) {
        return $m2 if $m1->{value} == 0;
        if ($m2->term_type == T_CONSTANT) {
            return $m2->new($m1->{value}*$m2->{value});
        }
    }
    elsif ($m2->term_type == T_CONSTANT) {
        return $m1 if $m2->{value} == 0;
    }

    return Math::Symbolic::Operator->new( '+', $m1, $m2 );
}

sub _quotient_rule {
    my ( $tree, $var, $cloned, $d_sub ) = @_;

    my ($op1, $op2) = @{$tree->{operands}};

    my ($do1, $do2);

    # y = f(x)/c; y' = f'/c
    if ($op2->is_simple_constant()) {
        $do1 = $d_sub->( $op1, $var, 0 );
        my $val = $op2->value();

        if ($val == 0) {
            return $tree->new('/', $do1, $op2->new()); # inf!
        }
        elsif ($val == 1) {
            return $do1; # f/1
        }
        return $tree->new('*', Math::Symbolic::Constant->new(1/$val), $do1);
    }
    # y = c/f(x) => y' = -c*f'(x)/f^2(x)
    elsif ($op1->is_simple_constant()) {
        $do2 = $d_sub->( $op2, $var, 0 );
        my $val = $op1->value();
        
        if ($val == 0) {
            return Math::Symbolic::Constant->zero(); # 0*f'/f
        }

        my $tdo2 = $do2->term_type();
        if ($tdo2 == T_CONSTANT) {
            return $do2->zero() if $do2->{value} == 0; # c*0/f
            return $tree->new(
                '/', $do2->new(-1.*$val*$do2->{value}),
                     $tree->new('^', $op2, 2)
            );
        }
        else {
            return $tree->new(
                '*', Math::Symbolic::Constant->new(-1*$val),
                $tree->new('/', $do2, $tree->new('^', $op2, Math::Symbolic::Constant->new(2)))
            )
        }
    }

    $do1 = $d_sub->( $op1, $var, 0 ) if not $do1;
    $do2 = $d_sub->( $op2, $var, 0 ) if not $do2;

    my $m1  = Math::Symbolic::Operator->new( '*', $do1, $op2 );
    my $m2  = Math::Symbolic::Operator->new( '*', $op1, $do2 );

    # f' = 0
    if ($do1->is_zero()) {
        $m1 = undef;
    }
    # f' = 1
    elsif ($do1->is_one()) {
        $m1 = $op2->new();
    }

    # g' = 0
    if ($do2->is_zero()) {
        $m2 = undef;
    }
    elsif ($do2->is_one()) {
        $m2 = $op1->new();
    }

    my $upper;
    # -g'f / g^2
    if (not defined $m1) {
        # f'=g'=0
        return Math::Symbolic::Constant->zero() if not defined $m2;
        $upper = $tree->new('neg', $m2);
    }
    # f'g / g^2 = f'/g
    elsif (not defined $m2) {
        return $tree->new('/', $do1, $op2);
    }

    my $m3 = $tree->new('^', $op2, Math::Symbolic::Constant->new(2));
    if (not defined $upper) {
      $upper = Math::Symbolic::Operator->new( '-', $m1, $m2 );
    }
    return Math::Symbolic::Operator->new( '/', $upper, $m3 );
}

sub _logarithmic_chain_rule_after_ln {
    my ( $tree, $var, $cloned, $d_sub ) = @_;

    # y(x)=u^v
    # y'(x)=y*(d/dx ln(y))
    # y'(x)=y*(d/dx (v*ln(u)))
    my ($u, $v) = @{$tree->{operands}};

    # This is a special case:
    # y(x)=u^CONST
    # y'(x)=CONST*y* d/dx ln(u)
    # y'(x)=CONST*y* u' / u
    if ($v->term_type() == T_CONSTANT) {

        # y=VAR^CONST
        if ($u->term_type() == T_VARIABLE) {
            my $d = $d_sub->($u, $var, 0);
            my $dtt = $d->term_type();
            if ($dtt == T_CONSTANT) {
                # not our var
                return Math::Symbolic::Constant->zero() if $d->{value} == 0;
                # our var
                return Math::Symbolic::Constant->one() if $v->{value} == 1;
                return $tree->new('*', $v->new(), $u->new()) if $v->{value} == 2;
                return $tree->new('*', $v->new(), $tree->new('^', $u->new(), $v->new($v->{value}-1)));
            }
            # otherwise: signature contains $var
        }
        return Math::Symbolic::Operator->new(
            '*', 
            Math::Symbolic::Operator->new(
                '*', $v->new(), $tree
            ),
            Math::Symbolic::Operator->new(
                '/', $d_sub->($u, $var, 0), $u->new()
            )
        );
    }

    my $e    = Math::Symbolic::Constant->euler();
    my $ln   = Math::Symbolic::Operator->new( 'log', $e, $u );
    my $mul1 = $ln->new( '*', $v, $ln );
    my $dmul = $d_sub->( $mul1, $var, 0 );
    $tree = $ln->new( '*', $tree, $dmul );
    return $tree;
}

sub _logarithmic_chain_rule {
    my ( $tree, $var, $cloned, $d_sub ) = @_;

    #log_a(y(x))=>y'(x)/(ln(a)*y(x))
    my ($a, $y) = @{$tree->{operands}};
    my $dy  = $d_sub->( $y, $var, 0 );

    # This would be y'/y
    if ($a->term_type() == T_CONSTANT and $a->{special} eq 'euler') {
        return Math::Symbolic::Operator->new('/', $dy, $y);
    }
    
    my $e    = Math::Symbolic::Constant->euler();
    my $ln   = Math::Symbolic::Operator->new( 'log', $e, $a );
    my $mul1 = $ln->new( '*', $ln, $y->new() );
    $tree = $ln->new( '/', $dy, $mul1 );
    return $tree;
}

sub _derivative_commutation {
    my ( $tree, $var, $cloned, $d_sub ) = @_;
    $tree->{operands}[0] = $d_sub->( $tree->{operands}[0], $var, 0 );
    return $tree;
}

sub _trigonometric_derivatives {
    my ( $tree, $var, $cloned, $d_sub ) = @_;
    my $op = Math::Symbolic::Operator->new();
    my $d_inner = $d_sub->( $tree->{operands}[0], $var, 0 );
    my $trig;
    my $type = $tree->type();
    if ( $type == U_SINE ) {
        $trig = $op->new( 'cos', $tree->{operands}[0] );
    }
    elsif ( $type == U_COSINE ) {
        $trig = $op->new( 'neg', $op->new( 'sin', $tree->{operands}[0] ) );
    }
    elsif ( $type == U_SINE_H ) {
        $trig = $op->new( 'cosh', $tree->{operands}[0] );
    }
    elsif ( $type == U_COSINE_H ) {
        $trig = $op->new( 'sinh', $tree->{operands}[0] );
    }
    elsif ( $type == U_TANGENT or $type == U_COTANGENT ) {
        $trig = $op->new(
            '/',
            Math::Symbolic::Constant->one(),
            $op->new(
                '^',
                $op->new( 'cos', $tree->op1() ),
                Math::Symbolic::Constant->new(2)
            )
        );
        $trig = $op->new( 'neg', $trig ) if $type == U_COTANGENT;
    }
    else {
        die "Trigonometric derivative applied to invalid operator.";
    }
    if ($d_inner->term_type() == T_CONSTANT) {
        my $spec = $d_inner->special();
        if ($spec eq 'zero') {
            return $d_inner;
        }
        elsif ($spec eq 'one') {
            return $trig;
        }
    }
    return $op->new( '*', $d_inner, $trig );
}

sub _inverse_trigonometric_derivatives {
    my ( $tree, $var, $cloned, $d_sub ) = @_;
    my $op = Math::Symbolic::Operator->new();
    my $d_inner = $d_sub->( $tree->{operands}[0], $var, 0 );
    my $trig;
    my $type = $tree->type();
    if ( $type == U_ARCSINE or $type == U_ARCCOSINE ) {
        my $one = $type == U_ARCSINE
            ? Math::Symbolic::Constant->one()
            : Math::Symbolic::Constant->new(-1);
        $trig = $op->new( '/', $one,
            $op->new( '-', $one->new(1), $op->new( '^', $tree->op1(), $one->new(2) ) )
        );
    }
    elsif ($type == U_ARCTANGENT
        or $type == U_ARCCOTANGENT )
    {
        my $one = $type == U_ARCTANGENT
            ? Math::Symbolic::Constant->one()
            : Math::Symbolic::Constant->new(-1);
        $trig = $op->new( '/', $one,
            $op->new( '+', $one->new(1), $op->new( '^', $tree->op1(), $one->new(2) ) )
        );
    }
    elsif ($type == U_AREASINE_H
        or $type == U_AREACOSINE_H )
    {
        my $one = Math::Symbolic::Constant->one();
        $trig = $op->new(
            '/', $one,
            $op->new(
                '^',
                $op->new(
                    ( $tree->type() == U_AREASINE_H ? '+' : '-' ),
                    $op->new( '^', $tree->op1(), $one->new(2) ),
                    $one
                ),
                $one->new(0.5)
            )
        );
    }
    else {
        die "Inverse trig. derivative applied to invalid operator.";
    }

    if ($d_inner->term_type() == T_CONSTANT) {
        my $spec = $d_inner->special();
        if ($spec eq 'zero') {
            return $d_inner;
        }
        elsif ($spec eq 'one') {
            return $trig;
        }
    }
    return $op->new( '*', $d_inner, $trig );
}

sub _inverse_atan2 {
    my ( $tree, $var, $cloned, $d_sub ) = @_;
    # d/df atan(y/x) = x^2/(x^2+y^2) * (d/df y/x)
    my ($op1, $op2) = @{$tree->{operands}}; 

    my $inner = $d_sub->( $op1->new()/$op2->new(), $var, 0 );
    # templates
    my $two = Math::Symbolic::Constant->new(2);
    my $op  = Math::Symbolic::Operator->new('+', $two, $two);

    my $result = $op->new('*',
      $op->new('/',
        $op->new('^', $op2->new(), $two->new()), 
        $op->new(
          '+', $op->new('^', $op2->new(), $two->new()),
          $op->new('^', $op1->new(), $two->new())
        )
      ),
      $inner
    );
    return $result;
}

=head1 SUBROUTINES

=cut

=head2 partial_derivative

Takes a Math::Symbolic tree and a Math::Symbolic::Variable as argument.
third argument is an optional boolean indicating whether or not the
tree has to be cloned before being derived. If it is true, the
subroutine happily stomps on any code that might rely on any components
of the Math::Symbolic tree that was passed to the sub as first argument.

=cut

sub partial_derivative {
    my $tree = shift;
    my $var  = shift;
    defined $var or die "Cannot derive using undefined variable.";
    if ( ref($var) eq '' ) {
        $var = Math::Symbolic::parse_from_string($var);
        croak "2nd argument to partial_derivative must be variable."
          if ( ref($var) ne 'Math::Symbolic::Variable' );
    }
    else {
        croak "2nd argument to partial_derivative must be variable."
          if ( ref($var) ne 'Math::Symbolic::Variable' );
    }

    my $cloned = shift;

    if ( not $cloned ) {
        $tree   = $tree->new();
        $cloned = 1;
    }

    if ( $tree->term_type() == T_OPERATOR ) {
        my $rulename =
          $Math::Symbolic::Operator::Op_Types[ $tree->type() ]->{derive};
        my $subref = $Rules{$rulename};

        die "Cannot derive using rule '$rulename'."
          unless defined $subref;
        $tree = $subref->( $tree, $var, $cloned, $Partial_Sub );
    }
    elsif ( $tree->term_type() == T_CONSTANT ) {
        $tree = Math::Symbolic::Constant->zero();
    }
    elsif ( $tree->term_type() == T_VARIABLE ) {
        if ( $tree->name() eq $var->name() ) {
            $tree = Math::Symbolic::Constant->one;
        }
        else {
            $tree = Math::Symbolic::Constant->zero;
        }
    }
    else {
        die "Cannot apply partial derivative to anything but a tree.";
    }

    return $tree;
}

=head2 total_derivative

Takes a Math::Symbolic tree and a Math::Symbolic::Variable as argument.
third argument is an optional boolean indicating whether or not the
tree has to be cloned before being derived. If it is true, the
subroutine happily stomps on any code that might rely on any components
of the Math::Symbolic tree that was passed to the sub as first argument.

=cut

sub total_derivative {
    my $tree = shift;
    my $var  = shift;
    defined $var or die "Cannot derive using undefined variable.";
    if ( ref($var) eq '' ) {
        $var = Math::Symbolic::parse_from_string($var);
        croak "Second argument to total_derivative must be variable."
          if ( ref($var) ne 'Math::Symbolic::Variable' );
    }
    else {
        croak "Second argument to total_derivative must be variable."
          if ( ref($var) ne 'Math::Symbolic::Variable' );
    }

    my $cloned = shift;

    if ( not $cloned ) {
        $tree   = $tree->new();
        $cloned = 1;
    }

    if ( $tree->term_type() == T_OPERATOR ) {
        my $var_name = $var->name();
        my @tree_sig = $tree->signature();
        if ( ( grep { $_ eq $var_name } @tree_sig ) > 0 ) {
            my $rulename =
              $Math::Symbolic::Operator::Op_Types[ $tree->type() ]->{derive};
            my $subref = $Rules{$rulename};

            die "Cannot derive using rule '$rulename'."
              unless defined $subref;
            $tree = $subref->( $tree, $var, $cloned, $Total_Sub );
        }
        else {
            $tree = Math::Symbolic::Constant->zero();
        }
    }
    elsif ( $tree->term_type() == T_CONSTANT ) {
        $tree = Math::Symbolic::Constant->zero();
    }
    elsif ( $tree->term_type() == T_VARIABLE ) {
        my $name     = $tree->name();
        my $var_name = $var->name();

        if ( $name eq $var_name ) {
            $tree = Math::Symbolic::Constant->one;
        }
        else {
            my @tree_sig = $tree->signature();
            my $is_dependent;
            foreach my $ident (@tree_sig) {
                if ( $ident eq $var_name ) {
                    $is_dependent = 1;
                    last;
                }
            }
            if ( $is_dependent ) {
                $tree =
                  Math::Symbolic::Operator->new( 'total_derivative', $tree,
                    $var );
            }
            else {
                $tree = Math::Symbolic::Constant->zero;
            }
        }
    }
    else {
        die "Cannot apply total derivative to anything but a tree.";
    }

    return $tree;
}

# Class data again.
$Partial_Sub = \&partial_derivative;
$Total_Sub   = \&total_derivative;

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

