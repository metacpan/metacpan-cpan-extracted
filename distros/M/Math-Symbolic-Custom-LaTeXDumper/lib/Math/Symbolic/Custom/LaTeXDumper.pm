
=encoding utf8

=head1 NAME

Math::Symbolic::Custom::LaTeXDumper - Math::Symbolic LaTeX output

=head1 SYNOPSIS

  use Math::Symbolic qw/parse_from_string/;
  use Math::Symbolic::Custom::LaTeXDumper;
  $term = parse_from_string(...);
  print $term->to_latex(...);

=head1 DESCRIPTION

This class provides the C<to_latex()> method for all L<Math::Symbolic>
trees. It is a rewrite of the C<to_latex()> method that was supplied by
C<Math::Symbolic> prior to version 0.201.

For details on how the custom method delegation model works, please have
a look at the C<Math::Symbolic::Custom> and C<Math::Symbolic::Custom::Base>
classes.

=head2 EXPORT

Please see the docs for C<Math::Symbolic::Custom::Base> for details, but
you should not try to use the standard Exporter semantics with this
class.

=head1 SUBROUTINES

=cut

package Math::Symbolic::Custom::LaTeXDumper;

use 5.006;
use strict;
use warnings;
no warnings 'recursion';

our $VERSION = '0.208';

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
      to_latex
      /
];

=head2 to_latex

It returns a LaTeX representation of the Math::Symbolic tree
it is called on. The LaTeX is meant to be included in a LaTeX
source document. It does not include an enclosing math environment.

The method uses named parameter passing style. Valid parameters are:

=over 4

=item implicit_multiplication

Used to turn on the '.' (C<\cdot>) operators for all multiplications.
Defaults to true, that is, the multiplication operators are not present.

=item no_fractions

Use '/' division operator instead of fractions.
Defaults to false, that is, use fractions. See also:
C<max_fractions> parameter.

=item max_fractions

Setting this parameter to a positive integer results in a limitation
of the number of nested fractions. It defaults to C<2>. Setting this to
C<0> results in arbitrarily nested fractions. To disable fractions
altogether, set the C<no_fraction> parameter.

=item exclude_signature

By default, the method includes all variables' signatures in parenthesis
if present. Set this to true to omit variable signatures.

=item replace_default_greek

By default, all variable names are outputted as LaTeX in a way that
makes them show up exactly as they did in your code. If you set
this option to true, Math::Symbolic will try to replace as many
greek character names with the appropriates symbols as possible.

Valid LaTeX symbols that are matched are:

  Lower case letters:
    alpha, beta, gamma, delta, epsilon, zeta, eta, theta,
    iota, kappa, lambda, mu, nu, xi, pi, rho, sigma,
    tau, upsilon, phi, chi, psi, omega
  
  Variant forms of small letters:
    varepsilon, vartheta, varpi, varrho, varsigma, varphi
  
  Upper case letters:
    Gamma, Delta, Theta, Lambda, Xi, Pi, Sigma, Upsilon, Phi,
    Psi, Omega

=item variable_mappings

Because not all variable names come out as you might want them to,
you may use the 'variable_mappings' option to replace variable names
in the output LaTeX stream with custom LaTeX. For example, the
variable x_i should probably indicate an 'x' with a subscripted i.
The argument to variable_mappings needs to be a hash reference which
contains variable name / LaTeX mapping pairs.

If a variable is replaced in the above fashion, other options that
modify the outcome of the conversion of variable names to LaTeX are
ignored.

=item subscript

Set this option to a true value to have all underscores in variable names
interpreted as subscripts. Once an underscore is encountered, the rest of the
variable name is treated as subscripted. If multiple underscores are found, this
mechanism works recursively.

Defaults to C<true>. Set to a false value to turn this off. This is automatically
turned off for variables that are mapped to custom LaTeX by the C<variable_mappings>
parameter.

=item no_sqrt

By default, the dumper tries to convert exponents of 1/2 (or 0.5) or anything
numeric that ends up being 1/2 to a square root. If this gives inconvenient results,
set this option to a true value to turn the heuristics off.

=back

=cut

sub to_latex {
    my $self   = shift;
    my %config = @_;
    $config{implicit_multiplication} = 1
      unless defined $config{implicit_multiplication};
    $config{no_fractions}      = 0 unless defined $config{no_fractions};
    $config{max_fractions}     = 2 if not exists $config{max_fractions};
    $config{exclude_signature} = 0 unless defined $config{exclude_signature};
    $config{no_sqrt} = 0 unless defined $config{no_sqrt};
    $config{replace_default_greek} = 0
      unless defined $config{replace_default_greek};

    $config{subscript} = 1 if not exists $config{subscript};

    $config{variable_mappings} = {}
      if not exists $config{variable_mappings}
      or not ref( $config{variable_mappings} ) eq 'HASH';

    my $default_greek = qr/(?<![a-zA-Z])
        alpha|beta|gamma|delta|epsilon|zeta|eta|theta
        |iota|kappa|lambda|mu|nu|xi|pi|rho|sigma|tau|upsilon
        |phi|chi|psi|omega
        |varepsilon|vartheta|varpi|varrho|varsigma|varphi
        |Gamma|Delta|Theta|Lambda|Xi|Pi|Sigma|Upsilon|Phi|Psi|Omega
        (?![a-zA-Z])
    /x;

    my $greekify = sub {
        my $s = $_[0];
        $s =~ s/($default_greek)/\\$1/g if $config{replace_default_greek};
        return $s;
    };
    
    my $subscriptify;
       $subscriptify = sub {
        my $s = $_[0];
        $s = '' if not defined $s;
        $s =~ s{_(.*)$}/length($1) == 1 ? "_$1" : '_{'.$subscriptify->($1).'}'/e if $config{subscript};
        return $s;
    };
    
    my $precedence = [
        1,     # B_SUM
        1,     # B_DIFFERENCE
        5,     # B_PRODUCT
        5,     # B_DIVISION
        15,    # U_MINUS
        20,    # U_P_DERIVATIVE
        20,    # U_T_DERIVATIVE
        25,    # B_EXP
        50,    # B_LOG
        50,    # U_SINE
        50,    # U_COSINE
        50,    # U_TANGENT
        50,    # U_COTANGENT
        50,    # U_ARCSINE
        50,    # U_ARCCOSINE
        50,    # U_ARCTANGENT
        50,    # U_ARCCOTANGENT
        50,    # U_SINE_H
        50,    # U_COSINE_H
        50,    # U_AREASINE_H
        50,    # U_AREACOSINE_H
        50,    # B_ARCTANGENT_TWO
    ];

    my $op_to_tex = [

        # B_SUM
        sub { "$_[0] + $_[1]" },

        # B_DIFFERENCE
        sub { "$_[0] - $_[1]" },

        # B_PRODUCT
        sub {
            $config{implicit_multiplication}
              ? "$_[0] $_[1]"
              : "$_[0] \\cdot $_[1]";
        },

        # B_DIVISION
        sub {
            if ( $config{no_fractions} ) {
                "$_[0] / $_[1]"
            }
            elsif (!$config{max_fractions} or $config{max_fractions} > $_[2]) {
                "\\frac{$_[0]}{$_[1]}"
            }
            else {
                "$_[0] / $_[1]"
            }
        },

        # U_MINUS
        sub { "-$_[0]" },

        # U_P_DERIVATIVE
        sub { "\\frac{\\partial $_[0]}{\\partial $_[1]}" },

        # U_T_DERIVATIVE
        sub { "\\frac{d $_[0]}{d $_[1]}" },

        # B_EXP
        sub {
            if (!$config{no_sqrt} and length($_[1]) > 2 and $_[1] !~ /\{|\}|\^|_|\-|\\|[A-DF-Za-df-z]/ and $_[1] - 0.5 < 1e-28) {
                return "\\sqrt{$_[0]}";
            }
            length($_[1]) == 1 ? "$_[0]^$_[1]" : "$_[0]^{$_[1]}"
        },

        # B_LOG
        sub { "\\log_{$_[0]}$_[1]" },

        # U_SINE
        sub { "\\sin{$_[0]}" },

        # U_COSINE
        sub { "\\cos{$_[0]}" },

        # U_TANGENT
        sub { "\\tan{$_[0]}" },

        # U_COTANGENT
        sub { "\\cot{$_[0]}" },

        # U_ARCSINE
        sub { "\\arcsin{$_[0]}" },

        # U_ARCCOSINE
        sub { "\\arccos{$_[0]}" },

        # U_ARCTANGENT
        sub { "\\arctan{$_[0]}" },

        # U_ARCCOTANGENT
        sub { "\\mathrm{cosec}{$_[0]}" },

        # U_SINE_H
        sub { "\\sinh{$_[0]}" },

        # U_COSINE_H
        sub { "\\cosh{$_[0]}" },

        # U_AREASINE_H
        sub { "\\mathrm{arsinh}{$_[0]}" },

        # U_AREACOSINE_H
        sub { "\\mathrm{arcosh}{$_[0]}" },

        # B_ARCTANGENT_TWO
        sub { "\\mathrm{atan2}{$_[0], $_[1]}" },
    ];

    my $tex = $self->descend(
        in_place       => 0,
        operand_finder => sub { $_[0]->descending_operands('all') },
        before         => sub {
            $_[0]->{__precedences} = [
                map {
                    my $ttype = $_->term_type();
                    if ( $ttype == T_OPERATOR ) {
                        $precedence->[ $_->type() ];
                    }
                    elsif ( $ttype == T_VARIABLE ) {
                        100;
                    }
                    elsif ( $ttype == T_CONSTANT ) {
                        100;
                    }
                    else { die "Should not be reached"; }
                  } @{ $_[0]->{operands} }
            ];
            my $fraction_depth = $_[0]->{__fract_depth} || 0;
            $fraction_depth++ if $_[0]->term_type() == T_OPERATOR and $_[0]->type() == B_DIVISION;
            for (@{ $_[0]->{operands} }) {
                $_->{__fract_depth} = $fraction_depth;
            }
            return ();
        },
        after => sub {
            my $self  = $_[0];
            my $ttype = $self->term_type();
            if ( $ttype == T_CONSTANT ) {
                $self->{text} = $self->value();
            }
            elsif ( $ttype == T_VARIABLE ) {
                my $name        = $self->name();
                my $edited_name = $name;
                if ( exists $config{variable_mappings}{$name} ) {
                    $edited_name = $config{variable_mappings}{$name};
                }
                else {
                    $edited_name = $greekify->($name);
                    $edited_name = $subscriptify->($edited_name);
                }
                unless ( $config{exclude_signature} ) {
                    my @sig =
                      map {
                        if ( exists $config{variable_mappings}{$_} )
                        {
                            $config{variable_mappings}{$_};
                        }
                        else {
                            $_ = $subscriptify->($_);
                            s/_/\_/g;
                            $greekify->($_);
                        }
                      }
                      grep $_ ne $name, $self->signature();
                    if (@sig) {
                        $self->{text} = "$edited_name(" . join( ', ', @sig ) . ')';
                    }
                    else {
                        $self->{text} = $edited_name;
                    }
                }
                else {
                    $self->{text} = $edited_name;
                }
            }
            elsif ( $ttype == T_OPERATOR ) {
                my $type  = $self->type();
                my $prec  = $precedence->[$type];
                my $precs = $self->{__precedences};
                my @ops   = @{ $self->{operands} };
                unless ( $type == B_DIVISION and !$config{no_fractions} ) {
                    for ( my $i = 0 ; $i < @ops ; $i++ ) {
                        my $obj = $ops[$i];
                        if ( $precs->[$i] < $prec
                             or $precs->[$i] == $prec && $prec == 50 # prec == 50 is a function call
                             or $i == 1 # second operand
                                && ($type == B_PRODUCT||$type == B_SUM||$type==B_DIFFERENCE)
                                && ($obj->term_type == T_CONSTANT && $obj->value < 0)
                                   || ($obj->term_type == T_OPERATOR && $obj->type == U_MINUS) )
                        {
                            $ops[$i]->{text} = '\\left(' . $ops[$i]->{text} . '\\right)'
                        }
                    }
                }
                my $fraction_depth = $self->{__fract_depth}||0;
                my $text = $op_to_tex->[$type]->((map $_->{text}, @ops), $fraction_depth);
                $self->{text} = $text;
            }
            else {
                die "Should never be reached";
            }
        },
    );

    return $tex->{text};
}

1;
__END__

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN. The module development takes place on
Sourceforge at http://sourceforge.net/projects/math-symbolic/

L<Math::Symbolic::Custom>
L<Math::Symbolic::Custom::DefaultMods>
L<Math::Symbolic::Custom::DefaultDumpers>
L<Math::Symbolic::Custom::DefaultTests>
L<Math::Symbolic>

=head1 AUTHOR

Steffen Müller, C<smueller@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, 2008, 2011, 2013 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
