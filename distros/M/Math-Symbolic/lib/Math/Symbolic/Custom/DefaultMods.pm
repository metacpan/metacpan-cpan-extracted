
=encoding utf8

=head1 NAME

Math::Symbolic::Custom::DefaultMods - Default Math::Symbolic transformations

=head1 SYNOPSIS

  use Math::Symbolic;

=head1 DESCRIPTION

This is a class of default transformations for Math::Symbolic trees. Likewise,
Math::Symbolic::Custom::DefaultTests defines default tree testing
routines.
For details on how the custom method delegation model works, please have
a look at the Math::Symbolic::Custom and Math::Symbolic::Custom::Base
classes.

=head2 EXPORT

Please see the docs for Math::Symbolic::Custom::Base for details, but
you should not try to use the standard Exporter semantics with this
class.

=head1 SUBROUTINES

=cut

package Math::Symbolic::Custom::DefaultMods;

use 5.006;
use strict;
use warnings;
no warnings 'recursion';

our $VERSION = '0.612';

use Math::Symbolic::Custom::Base;
BEGIN { *import = \&Math::Symbolic::Custom::Base::aggregate_import }

use Math::Symbolic::ExportConstants qw/:all/;

use Carp;

# Class Data: Special variable required by Math::Symbolic::Custom
# importing/exporting functionality.
# All subroutines that are to be exported to the Math::Symbolic::Custom
# namespace should be listed here.

our $Aggregate_Export = [
    qw/
      apply_derivatives
      apply_constant_fold
      mod_add_constant
      mod_multiply_constant
      /
];

=head2 apply_derivatives()

Never modifies the tree in-place, but returns a modified copy of the
original tree instead.

Applied to variables and constants, this method just clones.

Applied to operators and if the operator is a derivative, this applies
the derivative to the derivative's first operand.

Regardless what kind of operator this is called on, apply_derivatives
will be applied recursively on its operands.

If the first parameter to this function is an integer, at maximum that
number of derivatives are applied (from top down the tree if possible).

=cut

sub apply_derivatives {
    my $tree = shift;
    my $n    = shift || -1;

    return $tree->descend(
        in_place => 0,
        before   => sub {
            my $tree  = shift;
            my $ttype = $tree->term_type();
            if ( $ttype == T_CONSTANT || $ttype == T_VARIABLE ) {
                return undef;
            }
            elsif ( $ttype == T_OPERATOR ) {
                my $max_derivatives = $n;
                my $type            = $tree->type();

                while (
                    $n
                    && (   $type == U_P_DERIVATIVE
                        or $type == U_T_DERIVATIVE )
                  )
                {
                    my $op = $Math::Symbolic::Operator::Op_Types[$type];

                    my $operands    = $tree->{operands};
                    my $application = $op->{application};

                    if (    $type == U_T_DERIVATIVE
                        and $operands->[0]->term_type() == T_VARIABLE )
                    {
                        my @sig = $operands->[0]->signature();

                        my $name = $operands->[1]->name();

                        if (
                            ( grep { $_ eq $name } @sig ) > 0
                            and not(@sig == 1
                                and $sig[0] eq $name )
                          )
                        {
                            return undef;
                        }
                    }
                    $tree->replace( $application->(@$operands) );
                    return undef
                      unless $tree->term_type() == T_OPERATOR;

                    $type = $tree->type();
                    $n--;
                }
                return ();
            }
            else {
                croak "apply_derivatives called on invalid " . "tree type.";
            }

            die "Sanity check in apply_derivatives() should not "
              . "be reached.";
        },
    );
}

=head2 apply_constant_fold()

Does not modify the tree in-place by default, but returns a modified copy
of the original tree instead. If the first argument is true, the tree will
not be cloned. If it is false or not existant, the tree will be cloned.

Applied to variables and constants, this method just clones.

Applied to operators, all tree segments that contain constants and
operators only will be replaced with Constant objects.

=cut

sub apply_constant_fold {
    my $tree     = shift;
    my $in_place = shift;

    return $tree->descend(
        in_place => $in_place,
        before   => sub {
            my $tree = shift;
            if ( $tree->is_simple_constant() ) {
                $tree->replace( $tree->apply() )
                  unless $tree->term_type() == T_CONSTANT;
                return undef;
            }

            return undef if $tree->term_type() == T_VARIABLE;
            return { in_place => 1, descend_into => [] };
        }
    );

    return $tree;
}

=head2 mod_add_constant

Given a constant (object or number) as argument, this method tries
hard to fold it into an existing constant of the object this is called
on is already a sum or a difference.

Basically, this is the same as C<$tree + $constant> but does some
simplification.

=cut

sub mod_add_constant {
    my $tree = shift;
    my $constant = shift;

    return $tree if not $constant;
    $constant = $constant->value() if ref($constant);
    
    my $tt = $tree->term_type();
    if ($tt == T_CONSTANT) {
        return Math::Symbolic::Constant->new($tree->{value}+$constant);
    }
    elsif ($tt == T_OPERATOR) {
        my $type = $tree->type();

        if ($type == B_SUM || $type == B_DIFFERENCE) {
            my $ops = $tree->{operands};
            my $const_op;
            if ($ops->[0]->is_simple_constant()) {
                $const_op = 0;
            } elsif ($ops->[1]->is_simple_constant()) {
                $const_op = 1;
            }
            if (defined $const_op) {
                my $value = $ops->[$const_op]->value();
                my $other = $ops->[($const_op+1)%2];

                if ($const_op == 0) {
                    $value += $constant;
                }
                else { # second
                    $value = $type==B_SUM ? $value + $constant : $value - $constant;
                }

                if ($value == 0) {
                    return $other if $const_op == 1 or $type == B_SUM;
                    return Math::Symbolic::Constant->new(-$other->{value});
                }
                return Math::Symbolic::Operator->new(
                    ($type == B_DIFFERENCE ? '-' : '+'), # op-type
                    $const_op == 0 # order of ops 
                      ?($value, $other)
                      :($other, $value)
                );
            }
            if ($ops->[1]->term_type() == T_OPERATOR) {
                my $otype = $ops->[1]->type();
                if ($otype == B_SUM || $otype == B_DIFFERENCE) {
                    return Math::Symbolic::Operator->new(
                        ($type == B_SUM ? '+' : '-'),
                        $ops->[0],
                        $ops->[1]->mod_add_constant($constant)
                    );
                }
            }
            else {
                return Math::Symbolic::Operator->new(
                    ($type == B_SUM ? '+' : '-'),
                    $ops->[0]->mod_add_constant($constant),
                    $ops->[1],
                );
            }
        }
    }

    # fallback: variable, didn't apply, etc.
    return Math::Symbolic::Operator->new(
        '+', Math::Symbolic::Constant->new($constant), $tree
    );
}


=head2 mod_multiply_constant

Given a constant (object or number) as argument, this method tries
hard to fold it into an existing constant of the object this is called
on is already a product or a division.

Basically, this is the same as C<$tree * $constant> but does some
simplification.

=cut

sub mod_multiply_constant {
    my $tree = shift;
    my $constant = shift;

    return $tree if not defined $constant;
    $constant = $constant->value() if ref($constant);
    return $tree if $constant == 1;
    return Math::Symbolic::Constant->zero() if $constant == 0;
    
    my $tt = $tree->term_type();
    if ($tt == T_CONSTANT) {
        return Math::Symbolic::Constant->new($tree->{value}*$constant);
    }
    elsif ($tt == T_OPERATOR) {
        my $type = $tree->type();

        if ($type == B_PRODUCT || $type == B_DIVISION) {
            my $ops = $tree->{operands};
            my $const_op;
            if ($ops->[0]->is_simple_constant()) {
                $const_op = 0;
            } elsif ($ops->[1]->is_simple_constant()) {
                $const_op = 1;
            }
            if (defined $const_op) {
                my $value = $ops->[$const_op]->value();
                my $other = $ops->[($const_op+1)%2];

                if ($const_op == 0) {
                    $value *= $constant;
                }
                else { # second
                    $value = $type==B_PRODUCT ? $value * $constant : $value / $constant;
                }

                if ($value == 1) {
                    return $other if $const_op == 1 or $type == B_PRODUCT;
                    return Math::Symbolic::Constant->new(1/$other->{value});
                }
                return Math::Symbolic::Operator->new(
                    ($type == B_DIVISION ? '/' : '*'), # op-type
                    $const_op == 0 # order of ops 
                      ?($value, $other)
                      :($other, $value)
                );
            }
            if ($ops->[1]->term_type() == T_OPERATOR) {
                my $otype = $ops->[1]->type();
                if ($otype == B_PRODUCT || $otype == B_DIVISION) {
                    return Math::Symbolic::Operator->new(
                        ($type == B_PRODUCT ? '*' : '/'),
                        $ops->[0],
                        $ops->[1]->mod_multiply_constant($constant)
                    );
                }
            }
            else {
                return Math::Symbolic::Operator->new(
                    ($type == B_PRODUCT ? '*' : '('),
                    $ops->[0]->mod_multiply_constant($constant),
                    $ops->[1],
                );
            }
        }
    }

    # fallback: variable, didn't apply, etc.
    return Math::Symbolic::Operator->new(
        '*', Math::Symbolic::Constant->new($constant), $tree
    );
}

=begin comment

warn "mod_join_simple to be implemented in DefaultMods!";
sub mod_join_simple {
    my $o1   = shift;
    my $o2   = shift;
    my $type = shift;

    if ( $type == B_PRODUCT ) {
        return undef
          unless Math::Symbolic::Custom::is_identical_base( $o1, $o2 );

        my $tt1 = $o1->term_type();
        my $tt2 = $o2->term_type();
        my ( $base, $exp1 ) =
            ( $tt1 == T_OPERATOR and $o1->type() == B_EXP )
          ? ( $o1->op1(), $o1->op2() )
          : ( $o1, Math::Symbolic::Constant->one() );

        my $exp2 =
          ( $tt2 == T_OPERATOR and $o2->type() == B_EXP )
          ? $o2->op2()
          : Math::Symbolic::Constant->one();

        return Math::Symbolic::Operator->new( '^', $base,
            Math::Symbolic::Operator->new( '+', $exp1, $exp2 )->simplify() );
    }
}

=end comment

=cut

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

L<Math::Symbolic::Custom>
L<Math::Symbolic::Custom::DefaultDumpers>
L<Math::Symbolic::Custom::DefaultTests>
L<Math::Symbolic>

=cut
