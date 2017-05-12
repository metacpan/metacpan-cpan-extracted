
=encoding utf8

=head1 NAME

Math::Symbolic::Custom::DefaultTests - Default Math::Symbolic tree tests

=head1 SYNOPSIS

  use Math::Symbolic;

=head1 DESCRIPTION

This is a class of default tests for Math::Symbolic trees. Likewise,
Math::Symbolic::Custom::DefaultMods defines default tree transformation
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

package Math::Symbolic::Custom::DefaultTests;

use 5.006;
use strict;
use warnings;
use Data::Dumper; # for numerical equivalence test

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
      is_one
      is_zero
      is_zero_or_one
      is_sum
      is_constant
      is_simple_constant
      is_integer
      is_identical
      is_identical_base
      test_num_equiv
      /
];

=head2 is_zero()

Returns true (1) of the tree is a constant and '0'. Returns
false (0) otherwise.

=cut

sub is_zero {
    my $tree = shift;
    return 0 unless $tree->term_type() == T_CONSTANT;
    return 1 if $tree->{value} == 0;
    return 0;
}

=head2 is_one()

Returns true (1) of the tree is a constant and '1'. Returns
false (0) otherwise.

=cut

sub is_one {
    my $tree = shift;
    return 0 unless $tree->term_type() == T_CONSTANT;
    return 1 if $tree->{value} == 1;
    return 0;
}

=head2 is_zero_or_one()

Returns true ('1' for 1, '0E0' for 0) of the tree is a constant and '1' or '0'.
Returns false (0) otherwise.

=cut

sub is_zero_or_one {
    my $tree = shift;
    return 0 unless $tree->term_type() == T_CONSTANT;
    return 1 if $tree->{value} == 1;
    return "0E0" if $tree->{value} == 0;
    return 0;
}

=head2 is_integer()

is_integer() returns a boolean.

It returns true (1) if the tree is a constant object representing an
integer value. It does I<not> compute the value of the tree.
(eg. '5*10' is I<not> considered an integer, but '50' is.)

It returns false (0) otherwise.

=cut

sub is_integer {
    my $tree = shift;
    return 0 unless $tree->term_type() == T_CONSTANT;
    my $value = $tree->value();
    return ( int($value) == $value );
}

=head2 is_simple_constant()

is_simple_constant() returns a boolean.

It returns true if the tree consists of only constants and operators.
As opposed to is_constant(), is_simple_constant() does not apply derivatives
if necessary.

It returns false (0) otherwise.

=cut

sub is_simple_constant {
    my $tree = shift;

    my $return = 1;
    $tree->descend(
        in_place => 1,
        before   => sub {
            my $tree  = shift;
            my $ttype = $tree->term_type();
            if ( $ttype == T_CONSTANT ) {
                return undef;
            }
            elsif ( $ttype == T_VARIABLE ) {
                $return = 0;
                return undef;
            }
            elsif ( $ttype == T_OPERATOR ) {
                return ();
            }
            else {
                croak "is_simple_constant called on " . "invalid tree type.";
            }
        },
    );
    return $return;
}

=head2 is_constant()

is_constant() returns a boolean.

It returns true (1) if the tree consists of only constants and operators or
if it becomes a tree of only constants and operators after application
of derivatives.

It returns false (0) otherwise.

If you need not pay the price of applying derivatives, you should use the
is_simple_constant() method instead.

=cut

sub is_constant {
    my $tree = shift;

    my $return = 1;
    $tree->descend(
        in_place => 1,
        before   => sub {
            my $tree  = shift;
            my $ttype = $tree->term_type();
            if ( $ttype == T_CONSTANT ) {
                return undef;
            }
            elsif ( $ttype == T_VARIABLE ) {
                $return = 0;
                return undef;
            }
            elsif ( $ttype == T_OPERATOR ) {
                my $tree = $tree->apply_derivatives();
                $ttype = $tree->term_type();
                return undef if $ttype == T_CONSTANT;
                ( $return = 0 ), return undef
                  if $ttype == T_VARIABLE;

                return { descend_into => [ @{ $tree->{operands} } ], };
            }
            else {
                croak "is_constant called on " . "invalid tree type.";
            }
        },
    );
    return $return;
}

=head2 is_identical()

is_identical() returns a boolean.

It compares the tree it is called on to its first argument. If the first
argument is not a Math::Symbolic tree, it is sent through the parser.

is_identical() returns true (1) if the trees are completely identical. That
includes operands of commutating operators having the same order, etc. This
does I<not> test of mathematical equivalence! (Which is B<much, much> harder
to test for. If you know how to, I<please> let me know!)

It returns false (0) otherwise.

=cut

sub is_identical {
    my $tree1 = shift;
    my $tree2 = shift;
    $tree2 = Math::Symbolic::parse_from_string($tree2)
      if not ref($tree2) =~ /^Math::Symbolic/;

    my $tt1 = $tree1->term_type();
    my $tt2 = $tree2->term_type();

    if ( $tt1 != $tt2 ) {
        return 0;
    }
    else {
        if ( $tt1 == T_VARIABLE ) {
            return 0 if $tree1->name() ne $tree2->name();
            my @sig1 = $tree1->signature();
            my @sig2 = $tree2->signature();
            return 0 if scalar(@sig1) != scalar(@sig2);
            for ( my $i = 0 ; $i < @sig1 ; $i++ ) {
                return 0 if $sig1[$i] ne $sig2[$i];
            }
            return 1;
        }
        elsif ( $tt1 == T_CONSTANT ) {
            my $sp1 = $tree1->special();
            my $sp2 = $tree2->special();
            if (    defined $sp1
                and defined $sp2
                and $sp1 eq $sp2
                and $sp1 ne ''
                and $sp1 =~ /\S/ )
            {
                return 1;
            }
            return 1 if $tree1->value() == $tree2->value();
            return 0;
        }
        elsif ( $tt1 == T_OPERATOR ) {
            my $t1 = $tree1->type();
            my $t2 = $tree2->type();
            return 0 if $t1 != $t2;
            return 0
              if @{ $tree1->{operands} } != @{ $tree2->{operands} };

            my $i = 0;
            foreach ( @{ $tree1->{operands} } ) {
                return 0
                  unless is_identical( $_, $tree2->{operands}[ $i++ ] );
            }
            return 1;
        }
        else {
            croak "is_identical() called on invalid term type.";
        }
        die "Sanity check in is_identical(). Should not be reached.";
    }
}

=head2 is_identical_base

is_identical_base() returns a boolean.

It compares the tree it is called on to its first argument. If the first
argument is not a Math::Symbolic tree, it is sent through the parser.

is_identical_base() returns true (1) if the trees are identical or
if they are exponentiations with the same base. The same gotchas that
apply to is_identical apply here, too.

For example, 'x*y' and '(x*y)^e' result in a true return value because
'x*y' is equal to '(x*y)^1' and this has the same base as '(x*y)^e'.

It returns false (0) otherwise.

=cut

sub is_identical_base {
    my $o1 = shift;
    my $o2 = shift;
    $o2 = Math::Symbolic::parse_from_string($o2)
      if ref($o2) !~ /^Math::Symbolic/;

    my $tt1 = $o1->term_type();
    my $tt2 = $o2->term_type();

    my $so1 =
      ( $tt1 == T_OPERATOR and $o1->type() == B_EXP ) ? $o1->op1() : $o1;
    my $so2 =
      ( $tt2 == T_OPERATOR and $o2->type() == B_EXP ) ? $o2->op1() : $o2;

    return Math::Symbolic::Custom::is_identical( $so1, $so2 );
}

=head2 is_sum()

(beta)

is_constant() returns a boolean.

It returns true (1) if the tree contains no variables (because it can then
be evaluated to a single constant which is a sum). It also returns true if
it is a sum or difference of constants and variables. Furthermore, it is
true for products of integers and constants because those products are really
sums of variables.
If none of the above cases match, it applies all derivatives and tries again.

It returns false (0) otherwise.

Please contact the author in case you encounter bugs in the specs or
implementation. The heuristics aren't all that great.

=cut

sub is_sum {
    my $tree = shift;

    my $return = 1;
    $tree->descend(
        in_place => 1,
        before   => sub {
            my $tree  = shift;
            my $ttype = $tree->term_type();

            if ( $ttype == T_CONSTANT or $ttype == T_VARIABLE ) {
                return undef;
            }
            elsif ( $ttype == T_OPERATOR ) {
                my $type = $tree->type();
                if (   $type == B_SUM
                    or $type == B_DIFFERENCE
                    or $type == U_MINUS )
                {
                    return ();
                }
                elsif ( $type == B_PRODUCT ) {
                    $return = $tree->{operands}[0]->is_integer()
                      || $tree->{operands}[1]->is_integer();
                    return undef;
                }
                elsif ($type == U_P_DERIVATIVE
                    or $type == U_T_DERIVATIVE )
                {
                    my $tree = $tree->apply_derivatives();
                    $tree = $tree->simplify();
                    my $ttype = $tree->term_type();
                    return undef
                      if ( $ttype == T_CONSTANT
                        or $ttype == T_VARIABLE );

                    if ( $ttype == T_OPERATOR ) {
                        my $type = $tree->type();
                        if (   $type == U_P_DERIVATIVE
                            || $type == U_T_DERIVATIVE )
                        {
                            $return = 0;
                            return undef;
                        }
                        else {
                            return { descend_into => [$tree] };
                        }
                    }
                    else {
                        die "apply_derivatives "
                          . "screwed the pooch in "
                          . "is_sum().";
                    }
                }
                elsif ( is_constant($tree) ) {
                    return undef;
                }
                else {
                    $return = 0;
                    return undef;
                }
            }
            else {
                croak "is_sum called on invalid tree type.";
            }
            die;
        },
    );
    return $return;
}

=head2 test_num_equiv()

Takes another Math::Symbolic tree or a code ref as first
argument. Tests the tree
it is called on and the one passed in as first argument for
equivalence by sampling random numbers for their parameters and
evaluating them.

This is no guarantee that the functions are actually similar. The
computation required for this test may be very high for large
numbers of tests.

In case of a subroutine reference passed in, the values of the
parameters of the Math::Symbolic tree are passed to the sub
ref sorted by the parameter names.

Following the test-tree, there may be various options as key/value
pairs:

  limits: A hash reference with parameter names as keys and code refs
          as arguments. A code ref for parameter 'x', will be executed
          for every number of 'x' that is generated. If the code
          returns false, the number is discarded and regenerated.
  tests:  The number of tests to carry out. Default: 20
  epsilon: The accuracy of the numeric comparison. Default: 1e-7
  retries: The number of attempts to make if a function evaluation
           throws an error.
  upper:   Upper limit of the random numbers. Default: 10
  lower:   Lower limit of the random numbers. Default: -10

=cut

sub test_num_equiv {
    my ($t1, $t2) = (shift(), shift());
    if (ref($t1) !~ /^Math::Symbolic/) {
        croak("test_numeric_equivalence() must be called on Math::Symbolic tree");
    }
    if (ref($t2) !~ /^Math::Symbolic/ and ref($t2) ne 'CODE') {
        croak("first argument to test_numeric_equivalence() must be a Math::Symbolic tree or a code reference");
    }

    my $is_code = ref($t2) eq 'CODE' ? 1 : 0;

    my %args = @_;
    my $limits = $args{limits} || {};
    my $tests = $args{tests} || 20;
    my $eps = $args{epsilon} || 1e-7;
    my $retries = $args{retries} || 5;
    my $upper = $args{upper} || 10;
    my $lower = $args{lower} || -10;

    my @s1 = $t1->signature();
    my @s2 = $is_code ? () : $t2->signature();

    my %sig = map {($_=>undef)} @s1, @s2;

    my $mult = $upper-$lower;

    my $retry = 0;
    foreach (1..$tests) {
        croak("Could not evaluate test functions with numbers -10..10")
          if $retry > $retries-1;
        for (keys %sig) {
            my $num = rand()*$mult - $mult/2;
            redo if $limits->{$_} and not $limits->{$_}->($num);
            $sig{$_} = $num;
        }

        no warnings;
        my($y1, $y2);
        eval {$y1 = $t1->value(%sig);};
        if ($@) {
            warn "error during evaluation: $@";
            $retry++;
            $mult /= 2;
            redo;
        }
        if ($is_code) {
            eval {$y2 = $t2->(map {$sig{$_}} sort keys %sig)};
        }
        else {
            eval {$y2 = $t2->value(%sig);};
        }
        if ($@) {
            warn "error during evaluation: $@";
            $retry++;
            $mult /= 2;
            redo;
        }

        if (not defined $y1) {
            warn "Result of '$t1' not defined; ".Dumper(\%sig);
            next if not defined $y2;
            $retry++;
            redo;
        }
        elsif (not defined $y2) {
            warn "Result of '$t2' not defined; ".Dumper(\%sig);
            $retry++;
            redo;
        }


        warn("1: $y1, 2: $y2; ".Dumper(\%sig)), return 0 if $y1+$eps < $y2 or $y1-$eps > $y2;

        $mult = $upper-$lower;
        $retry = 0;
    }

    return 1;
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

L<Math::Symbolic::Custom>
L<Math::Symbolic::Custom::DefaultDumpers>
L<Math::Symbolic::Custom::DefaultMods>
L<Math::Symbolic>

=cut
