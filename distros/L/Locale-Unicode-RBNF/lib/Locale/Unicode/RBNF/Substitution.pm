##----------------------------------------------------------------------------
## Unicode Rule-Based Number Format - ~/lib/Locale/Unicode/RBNF/Substitution.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/10/22
## Modified 2026/10/22
## All rights reserved
##
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# Port of ICU4C NFSubstitution and its subclasses (icu4c/source/i18n/nfsubs.cpp, ICU 79.1)
package Locale::Unicode::RBNF::Substitution;
BEGIN
{
    use strict;
    use warnings;
    if( $] < 5.013 )
    {
        no strict 'refs';
        unless( defined( &warnings::register_categories ) )
        {
            *warnings::_mkMask = sub
            {
                my $bit  = shift( @_ );
                my $mask = "";
                vec( $mask, $bit, 1 ) = 1;
                return( $mask );
            };

            *warnings::register_categories = sub
            {
                my @names = @_;
                foreach my $name ( @names )
                {
                    if( !defined( $warnings::Bits{ $name } ) )
                    {
                        $warnings::Offsets{ $name }  = $warnings::LAST_BIT;
                        $warnings::Bits{ $name }     = warnings::_mkMask( $warnings::LAST_BIT++ );
                        $warnings::DeadBits{ $name } = warnings::_mkMask( $warnings::LAST_BIT++ );
                        if( length( $warnings::Bits{ $name } ) > length( $warnings::Bits{all} ) )
                        {
                            $warnings::Bits{all}     .= "\x55";
                            $warnings::DeadBits{all} .= "\xaa";
                        }
                    }
                }
            };
        }
    }
    warnings::register_categories( 'Locale::Unicode::RBNF' );
    use vars qw( $VERSION $DBL_MAX $MAX_INT64_IN_DOUBLE );
    use POSIX ();
    use Scalar::Util qw( weaken );
    use Locale::Unicode::RBNF::DecimalFormat;
    use Locale::Unicode::RBNF::Util qw( :all );
    $DBL_MAX = POSIX::DBL_MAX;
    $MAX_INT64_IN_DOUBLE = 9007199254740991;
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

# Rule type constants, duplicated from Locale::Unicode::RBNF::Rule to avoid a circular use.
use constant {
    NEGATIVE_NUMBER     => -1,
    IMPROPER_FRACTION   => -2,
    PROPER_FRACTION     => -3,
    DEFAULT_RULE        => -4,
};

# NFSubstitution::makeSubstitution(): the token's first character and the rule's type decide
# which kind of substitution is created.
sub make
{
    my( $class, $pos, $rule, $predecessor, $rule_set, $formatter, $description, $st ) = @_;
    return if( $$st );
    return if( !length( $description ) );
    my $c = substr( $description, 0, 1 );
    my $bv = $rule->get_base_value;
    my $is_fraction_type = ( $bv == IMPROPER_FRACTION || $bv == PROPER_FRACTION || $bv == DEFAULT_RULE ) ? 1 : 0;
    if( $c eq '<' )
    {
        if( $bv == NEGATIVE_NUMBER )
        {
            $$st = 'U_PARSE_ERROR: << not allowed in negative-number rule';
            return;
        }
        elsif( $is_fraction_type )
        {
            return( Locale::Unicode::RBNF::Substitution::IntegralPart->new( $pos, $rule_set, $description, $st ) );
        }
        elsif( $rule_set->is_fraction_rule_set )
        {
            return( Locale::Unicode::RBNF::Substitution::Numerator->new( $pos, $bv, $formatter->_default_rule_set_object, $description, $st ) );
        }
        else
        {
            return( Locale::Unicode::RBNF::Substitution::Multiplier->new( $pos, $rule, $rule_set, $description, $st ) );
        }
    }
    elsif( $c eq '>' )
    {
        if( $bv == NEGATIVE_NUMBER )
        {
            return( Locale::Unicode::RBNF::Substitution::AbsoluteValue->new( $pos, $rule_set, $description, $st ) );
        }
        elsif( $is_fraction_type )
        {
            return( Locale::Unicode::RBNF::Substitution::FractionalPart->new( $pos, $rule_set, $description, $st ) );
        }
        elsif( $rule_set->is_fraction_rule_set )
        {
            $$st = 'U_PARSE_ERROR: >> not allowed in fraction rule set';
            return;
        }
        else
        {
            return( Locale::Unicode::RBNF::Substitution::Modulus->new( $pos, $rule, $predecessor, $rule_set, $description, $st ) );
        }
    }
    elsif( $c eq '=' )
    {
        return( Locale::Unicode::RBNF::Substitution::SameValue->new( $pos, $rule_set, $description, $st ) );
    }
    $$st = 'U_PARSE_ERROR: illegal substitution character in "' . $description . '"';
    return;
}

# NFSubstitution constructor. The description must begin and end with the same character.
sub new
{
    my( $this, $pos, $rule_set, $description, $st ) = @_;
    my $self = bless( { pos => $pos, rule_set => undef, number_format => undef }, ( ref( $this ) || $this ) );
    return( $self ) if( $$st );
    my $working = $description;
    if( length( $description ) >= 2 && substr( $description, 0, 1 ) eq substr( $description, -1 ) )
    {
        $working = substr( $description, 1, length( $description ) - 2 );
    }
    elsif( length( $description ) )
    {
        $$st = 'U_PARSE_ERROR: illegal substitution syntax "' . $description . '"';
        return( $self );
    }
    my $first = substr( $working, 0, 1 );
    if( !length( $working ) )
    {
        # "<<" or ">>" use the rule set the substitution belongs to.
        $self->{rule_set} = $rule_set;
    }
    elsif( $first eq '%' )
    {
        $self->{rule_set} = $rule_set->get_owner->_find_rule_set( $working, $st );
    }
    elsif( $first eq '#' || $first eq '0' )
    {
        my $sym = $rule_set->get_owner->{symbols};
        if( !$sym )
        {
            $$st = 'U_MISSING_RESOURCE_ERROR: no decimal format symbols';
            return( $self );
        }
        $self->{number_format} = Locale::Unicode::RBNF::DecimalFormat->new( $working, $sym, $st );
    }
    elsif( $first eq '>' )
    {
        # ">>>" bypasses the usual rule search and always uses the preceding rule.
        $self->{rule_set} = $rule_set;
    }
    else
    {
        $$st = 'U_PARSE_ERROR: illegal substitution syntax "' . $description . '"';
    }
    # Rule sets reference one another, and themselves, through substitutions.
    weaken( $self->{rule_set} ) if( $self->{rule_set} );
    return( $self );
}

sub calc_upper_bound { return( $_[1] ); }

sub compose_rule_value { return( $_[1] ); }

sub do_substitution_double
{
    my( $self, $number, $out, $pos, $rc, $st ) = @_;
    return if( $$st );
    my $n = $self->transform_double( $number );
    if( is_infinite( $n ) )
    {
        # This is probably a minus rule. Combine it with an infinite rule.
        return if( !$self->{rule_set} );
        my $inf_rule = $self->{rule_set}->find_double_rule( 9**9**9 );
        $inf_rule->do_format_double( $n, $out, $pos + $self->{pos}, $rc, $st ) if( $inf_rule );
        return;
    }
    # If the result is an integer, from here on we work in integer space.
    if( !is_nan( $n ) && $n == POSIX::floor( $n ) && $self->{rule_set} )
    {
        $self->{rule_set}->format_int( from_double( $n ), $out, $pos + $self->{pos}, $rc, $st );
    }
    elsif( $self->{rule_set} )
    {
        $self->{rule_set}->format_double( $n, $out, $pos + $self->{pos}, $rc, $st );
    }
    elsif( $self->{number_format} )
    {
        str_insert( $out, $pos + $self->{pos}, $self->{number_format}->format( $n, 0 ) );
    }
    return;
}

sub do_substitution_int
{
    my( $self, $number, $out, $pos, $rc, $st ) = @_;
    return if( $$st );
    if( $self->{rule_set} )
    {
        $self->{rule_set}->format_int( $self->transform_int( $number ), $out, $pos + $self->{pos}, $rc, $st );
    }
    elsif( $self->{number_format} )
    {
        if( $number <= $MAX_INT64_IN_DOUBLE )
        {
            str_insert( $out, $pos + $self->{pos}, $self->{number_format}->format( $self->transform_double( $number + 0.0 ), 0 ) );
        }
        else
        {
            # Beyond double precision, accuracy of the large number is favoured.
            str_insert( $out, $pos + $self->{pos}, $self->{number_format}->format( $self->transform_int( $number ), 1 ) );
        }
    }
    return;
}

sub get_pos { return( $_[0]->{pos} ); }

sub get_rule_set { return( $_[0]->{rule_set} ); }

sub is_modulus { return(0); }

sub set_decimal_format_symbols
{
    my( $self, $symbols, $st ) = @_;
    $self->{number_format}->set_symbols( $symbols ) if( $self->{number_format} );
    return;
}

# A no-op for all substitutions except multiplier and modulus substitutions.
sub set_divisor { return; }

sub to_string
{
    my $self = shift( @_ );
    my $t = $self->token_char;
    my $inner = '';
    if( $self->{rule_set} ) { $inner = $self->{rule_set}->get_name; }
    elsif( $self->{number_format} ) { $inner = $self->{number_format}->to_pattern; }
    return( $t . $inner . $t );
}

sub transform_double { return( $_[1] ); }

sub transform_int { return( $_[1] ); }

# NOTE: package Locale::Unicode::RBNF::Substitution::SameValue
# "==" in rule descriptions: passes the value through unchanged.
package Locale::Unicode::RBNF::Substitution::SameValue;
use parent -norequire, qw( Locale::Unicode::RBNF::Substitution );

sub new
{
    my( $this, $pos, $rule_set, $description, $st ) = @_;
    my $self = $this->SUPER::new( $pos, $rule_set, $description, $st );
    $$st = 'U_PARSE_ERROR: == is not a legal token' if( !$$st && $description eq '==' );
    return( $self );
}

sub calc_upper_bound { return( $_[1] ); }

sub compose_rule_value { return( $_[1] ); }

sub token_char { return( '=' ); }

sub transform_double { return( $_[1] ); }

sub transform_int { return( $_[1] ); }

# NOTE: package Locale::Unicode::RBNF::Substitution::Multiplier
# "<<" in a normal rule: divides the number by the rule's divisor and formats the quotient.
package Locale::Unicode::RBNF::Substitution::Multiplier;
use parent -norequire, qw( Locale::Unicode::RBNF::Substitution );
use POSIX ();
use Scalar::Util qw( weaken );
use Locale::Unicode::RBNF::Util qw( idiv pow_u64 to_i64 );

sub new
{
    my( $this, $pos, $rule, $rule_set, $description, $st ) = @_;
    my $self = $this->SUPER::new( $pos, $rule_set, $description, $st );
    $self->{divisor} = $rule->get_divisor;
    $self->{owning_rule} = $rule;
    weaken( $self->{owning_rule} );
    $$st = 'U_PARSE_ERROR: divisor of 0' if( !$$st && $self->{divisor} == 0 );
    return( $self );
}

sub calc_upper_bound { return( $_[0]->{divisor} ); }

sub compose_rule_value { return( $_[1] * $_[0]->{divisor} ); }

sub set_divisor
{
    my( $self, $radix, $exponent, $st ) = @_;
    $self->{divisor} = to_i64( pow_u64( $radix, $exponent ) );
    $$st = 'U_PARSE_ERROR: divisor of 0' if( $self->{divisor} == 0 );
    return;
}

sub token_char { return( '<' ); }

# Usually the number is floored, but when a DecimalFormat formats the result and there is no
# modulus substitution, the value is kept intact so that the DecimalFormat can round it.
sub transform_double
{
    my( $self, $n ) = @_;
    my $rule = $self->{owning_rule};
    my $mode = ( $rule && $rule->{formatter} ) ? ( $rule->{formatter}->{rounding_mode} // '' ) : '';
    if( $self->{rule_set} || ( $rule && $rule->has_modulus_substitution ) || $mode eq 'floor' )
    {
        return( POSIX::floor( $n / $self->{divisor} ) );
    }
    return( $n / $self->{divisor} );
}

sub transform_int { return( idiv( $_[1], $_[0]->{divisor} ) ); }

# NOTE: package Locale::Unicode::RBNF::Substitution::Modulus
# ">>" in a normal rule: formats the remainder of the division by the rule's divisor.
package Locale::Unicode::RBNF::Substitution::Modulus;
use parent -norequire, qw( Locale::Unicode::RBNF::Substitution );
use POSIX ();
use Scalar::Util qw( weaken );
use Locale::Unicode::RBNF::Util qw( imod pow_u64 to_i64 );

sub new
{
    my( $this, $pos, $rule, $predecessor, $rule_set, $description, $st ) = @_;
    my $self = $this->SUPER::new( $pos, $rule_set, $description, $st );
    $self->{divisor} = $rule->get_divisor;
    $self->{rule_to_use} = undef;
    return( $self ) if( $$st );
    $$st = 'U_PARSE_ERROR: divisor of 0' if( $self->{divisor} == 0 );
    # ">>>" short-circuits the rule search and goes straight to the preceding rule.
    if( $description eq '>>>' )
    {
        $self->{rule_to_use} = $predecessor;
        weaken( $self->{rule_to_use} ) if( $predecessor );
    }
    return( $self );
}

sub calc_upper_bound { return( $_[0]->{divisor} ); }

sub compose_rule_value
{
    my( $self, $new, $old ) = @_;
    return( $old - POSIX::fmod( $old, $self->{divisor} ) + $new );
}

sub do_substitution_double
{
    my( $self, $number, $out, $pos, $rc, $st ) = @_;
    return if( $$st );
    return( $self->SUPER::do_substitution_double( $number, $out, $pos, $rc, $st ) ) if( !$self->{rule_to_use} );
    $self->{rule_to_use}->do_format_double( $self->transform_double( $number ), $out, $pos + $self->{pos}, $rc, $st );
    return;
}

sub do_substitution_int
{
    my( $self, $number, $out, $pos, $rc, $st ) = @_;
    return if( $$st );
    return( $self->SUPER::do_substitution_int( $number, $out, $pos, $rc, $st ) ) if( !$self->{rule_to_use} );
    $self->{rule_to_use}->do_format_int( $self->transform_int( $number ), $out, $pos + $self->{pos}, $rc, $st );
    return;
}

sub is_modulus { return(1); }

sub set_divisor
{
    my( $self, $radix, $exponent, $st ) = @_;
    $self->{divisor} = to_i64( pow_u64( $radix, $exponent ) );
    $$st = 'U_PARSE_ERROR: divisor of 0' if( $self->{divisor} == 0 );
    return;
}

sub to_string
{
    my $self = shift( @_ );
    return( '>>>' ) if( $self->{rule_to_use} );
    return( $self->SUPER::to_string );
}

sub token_char { return( '>' ); }

sub transform_double { return( POSIX::fmod( $_[1], $_[0]->{divisor} ) ); }

sub transform_int { return( imod( $_[1], $_[0]->{divisor} ) ); }

# NOTE: package Locale::Unicode::RBNF::Substitution::IntegralPart
# "<<" in a fraction rule: formats the integral part of the number.
package Locale::Unicode::RBNF::Substitution::IntegralPart;
use parent -norequire, qw( Locale::Unicode::RBNF::Substitution );
use POSIX ();

sub calc_upper_bound { return( $Locale::Unicode::RBNF::Substitution::DBL_MAX ); }

sub compose_rule_value { return( $_[1] + $_[2] ); }

sub token_char { return( '<' ); }

sub transform_double { return( POSIX::floor( $_[1] ) ); }

sub transform_int { return( $_[1] ); }

# NOTE: package Locale::Unicode::RBNF::Substitution::FractionalPart
# ">>" in a fraction rule: formats the fractional part, either digit by digit, or with a
# fraction rule set.
package Locale::Unicode::RBNF::Substitution::FractionalPart;
use parent -norequire, qw( Locale::Unicode::RBNF::Substitution );
use POSIX ();
use Locale::Unicode::RBNF::Util qw( :all );

sub new
{
    my( $this, $pos, $rule_set, $description, $st ) = @_;
    my $self = $this->SUPER::new( $pos, $rule_set, $description, $st );
    $self->{by_digits} = 0;
    $self->{use_spaces} = 1;
    return( $self ) if( $$st );
    my $own = $self->{rule_set};
    if( $description eq '>>' || $description eq '>>>' || ( defined( $own ) && $own == $rule_set ) )
    {
        $self->{by_digits} = 1;
        $self->{use_spaces} = 0 if( $description eq '>>>' );
    }
    elsif( $own )
    {
        $own->make_into_fraction_rule_set;
    }
    else
    {
        $$st = 'U_PARSE_ERROR: fractional part substitution requires a rule set';
    }
    return( $self );
}

sub calc_upper_bound { return( 0.0 ); }

sub compose_rule_value { return( $_[1] + $_[2] ); }

sub do_substitution_double
{
    my( $self, $number, $out, $pos, $rc, $st ) = @_;
    return if( $$st );
    return( $self->SUPER::do_substitution_double( $number, $out, $pos, $rc, $st ) ) if( !$self->{by_digits} );
    # Each fraction digit is formatted as an integer with the owning rule set, starting with
    # the least significant digit, and including the zeros to the right of the decimal point.
    my $dl = dec_from_number( $number, 0 );
    dec_round( $dl, -20, 'half_even' );
    my $pad = 0;
    my $at = $pos + $self->{pos};
    for( my $didx = dec_lower_display_magnitude( $dl ); $didx < 0; $didx++ )
    {
        if( $pad && $self->{use_spaces} )
        {
            str_insert( $out, $at, ' ' );
        }
        else
        {
            $pad = 1;
        }
        $self->{rule_set}->format_int( dec_get_digit( $dl, $didx ), $out, $at, $rc, $st );
    }
    # If we would end up with "foo point", make sure we add a " zero" to the end.
    $self->{rule_set}->format_int( 0, $out, $at, $rc, $st ) if( !$pad );
    return;
}

# The integer version does nothing for a fractional part substitution.
sub do_substitution_int { return; }

sub token_char { return( '>' ); }

sub transform_double { return( $_[1] - POSIX::floor( $_[1] ) ); }

sub transform_int { return(0); }

# NOTE: package Locale::Unicode::RBNF::Substitution::AbsoluteValue
# ">>" in a negative-number rule: formats the absolute value.
package Locale::Unicode::RBNF::Substitution::AbsoluteValue;
use parent -norequire, qw( Locale::Unicode::RBNF::Substitution );

sub calc_upper_bound { return( $Locale::Unicode::RBNF::Substitution::DBL_MAX ); }

sub compose_rule_value { return( -$_[1] ); }

sub token_char { return( '>' ); }

sub transform_double { return( abs( $_[1] ) ); }

sub transform_int { return( $_[1] >= 0 ? $_[1] : -$_[1] ); }

# NOTE: package Locale::Unicode::RBNF::Substitution::Numerator
# "<<" in a fraction rule set: formats the numerator of the fraction whose denominator is the
# rule's base value. "<<" at the end ("<%foo<<") also emits leading zeros.
package Locale::Unicode::RBNF::Substitution::Numerator;
use parent -norequire, qw( Locale::Unicode::RBNF::Substitution );
use POSIX ();
use Locale::Unicode::RBNF::Util qw( :all );

sub new
{
    my( $this, $pos, $denominator, $rule_set, $description, $st ) = @_;
    my $with_zeros = ( length( $description ) >= 2 && substr( $description, -2 ) eq '<<' ) ? 1 : 0;
    my $desc = $with_zeros ? substr( $description, 0, length( $description ) - 1 ) : $description;
    if( !$rule_set )
    {
        $$st ||= 'U_PARSE_ERROR: no default rule set for the numerator substitution';
        return( bless( { pos => $pos }, ( ref( $this ) || $this ) ) );
    }
    my $self = $this->SUPER::new( $pos, $rule_set, $desc, $st );
    $self->{denominator} = $denominator + 0.0;
    $self->{ldenominator} = from_double( $self->{denominator} );
    $self->{with_zeros} = $with_zeros;
    return( $self );
}

sub calc_upper_bound { return( $_[0]->{denominator} ); }

sub compose_rule_value
{
    my( $self, $new, $old ) = @_;
    # Division by zero yields infinity or NaN in C++, whereas Perl would die.
    return( $new / $old ) if( $old );
    return( $new ? ( $new < 0 ? -9**9**9 : 9**9**9 ) : 9**9**9 - 9**9**9 );
}

sub do_substitution_double
{
    my( $self, $number, $out, $apos, $rc, $st ) = @_;
    return if( $$st );
    my $n = $self->transform_double( $number );
    my $long_nf = from_double( $n );
    my $rs = $self->{rule_set};
    if( $self->{with_zeros} && $rs )
    {
        # Leading zeros in the decimal expansion are emitted.
        my $nf = $long_nf;
        my $len = length( $$out );
        while( ( $nf *= 10 ) < $self->{denominator} )
        {
            str_insert( $out, $apos + $self->{pos}, ' ' );
            $rs->format_int( 0, $out, $apos + $self->{pos}, $rc, $st );
        }
        $apos += length( $$out ) - $len;
    }
    if( $n == $long_nf && $rs )
    {
        $rs->format_int( $long_nf, $out, $apos + $self->{pos}, $rc, $st );
    }
    elsif( $rs )
    {
        $rs->format_double( $n, $out, $apos + $self->{pos}, $rc, $st );
    }
    elsif( $self->{number_format} )
    {
        str_insert( $out, $apos + $self->{pos}, $self->{number_format}->format( $n, 0 ) );
    }
    return;
}

# The integer version does nothing for a numerator substitution.
sub do_substitution_int { return; }

sub token_char { return( '<' ); }

sub transform_double { return( POSIX::floor( $_[1] * $_[0]->{denominator} + 0.5 ) ); }

sub transform_int { return( $_[1] * $_[0]->{ldenominator} ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Locale::Unicode::RBNF::Substitution - Substitutions of a rule-based number format rule

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Internal module. This is a port of ICU4C C<NFSubstitution> and its subclasses C<SameValueSubstitution>, C<MultiplierSubstitution>, C<ModulusSubstitution>, C<IntegralPartSubstitution>, C<FractionalPartSubstitution>, C<AbsoluteValueSubstitution> and C<NumeratorSubstitution> (F<nfsubs.cpp>, ICU 79.1).

=head1 CONVENTIONS

The methods follow the ICU code they are ported from, and share these arguments:

=over 4

=item * C<$st>

A scalar reference that receives an error status, the equivalent of ICU C<UErrorCode>. It holds a message starting with the ICU error code name, such as C<U_PARSE_ERROR: ...>. Most methods do nothing if it is already set.

=item * C<$out>

A scalar reference to the string being built by formatting.

=item * C<$pos>

The position in C<$out> where the text produced is inserted. Rules are formatted by inserting their text into the output, then the text of their substitutions at their own offsets.

=item * C<$rc>

The recursion count, checked against C<$Locale::Unicode::RBNF::RuleSet::RECURSION_LIMIT> (64), as ICU does, to stop runaway rule descriptions.

=item * C<$pp>

A parse position, as an hash reference with the keys C<index> and C<error>, the equivalent of ICU C<ParsePosition>.

=item * C<$mask>

The bit mask of the non-numerical rules already executed during a parse, used by ICU to prevent infinite recursion through them.

=back

=head1 CLASSES

A substitution is the part of a rule text between two tokens, such as C<< << >>, C<< >%%frac> >> or C<=#,##0=>, which formats a value derived from the number, either with a rule set or with a L<Locale::Unicode::RBNF::DecimalFormat>. The token character and the type of the rule decide the class used, as ICU C<NFSubstitution::makeSubstitution()> does:

=over 4

=item * L</Locale::Unicode::RBNF::Substitution::SameValue>, for C<==>: the number itself.

=item * L</Locale::Unicode::RBNF::Substitution::Multiplier>, for C<< << >> in a normal rule: the number divided by the divisor of the rule.

=item * L</Locale::Unicode::RBNF::Substitution::Modulus>, for C<<< >> >>> in a normal rule: the remainder of the division by the divisor of the rule. C<<< >>> >>> uses the preceding rule directly.

=item * L</Locale::Unicode::RBNF::Substitution::IntegralPart>, for C<< << >> in a fraction rule: the integral part of the number.

=item * L</Locale::Unicode::RBNF::Substitution::FractionalPart>, for C<<< >> >>> in a fraction rule: the fractional part, digit by digit, or with a fraction rule set.

=item * L</Locale::Unicode::RBNF::Substitution::AbsoluteValue>, for C<<< >> >>> in a negative-number rule: the absolute value.

=item * L</Locale::Unicode::RBNF::Substitution::Numerator>, for C<< << >> in a fraction rule set: the numerator of the fraction whose denominator is the base value of the rule.

=back

All classes inherit from C<Locale::Unicode::RBNF::Substitution>, and override some of its methods, documented below for each class.

=head1 CONSTANTS

The rule types needed to choose the class of a substitution, duplicated from L<Locale::Unicode::RBNF::Rule> to avoid a circular C<use>: C<NEGATIVE_NUMBER> (-1), C<IMPROPER_FRACTION> (-2), C<PROPER_FRACTION> (-3) and C<DEFAULT_RULE> (-4).

The variable C<$DBL_MAX> holds the largest double, and C<$MAX_INT64_IN_DOUBLE> the largest integer a double holds exactly, 2^53 - 1.

=head1 CONSTRUCTORS

=head2 make

    my $sub = Locale::Unicode::RBNF::Substitution->make( $pos, $rule, $predecessor, $rule_set, $formatter, $token, \$st );

This is ICU C<NFSubstitution::makeSubstitution()>: it creates the substitution of the class matching the first character of the token and the type of the rule C<$rule>, as described in L</CLASSES>, at the offset C<$pos> of the rule text. C<$rule_set> is the rule set owning the rule, C<$predecessor> the preceding rule, used by C<<< >>> >>>, and C<$formatter> the L<Locale::Unicode::RBNF> object, whose default rule set a numerator substitution uses.

It returns the substitution, or an empty list if the token is empty or an error occurred, in which case C<$st> is set.

=head2 new

    my $sub = Locale::Unicode::RBNF::Substitution::SameValue->new( $pos, $rule_set, $token, \$st );

This is the constructor of ICU C<NFSubstitution>, shared by all classes. The token must begin and end with the same character. What is between them selects how the value is formatted: nothing, or C<< > >> for C<<< >>> >>>, means the rule set owning the rule, a name starting with C<%> another rule set of the formatter, and a pattern starting with C<#> or C<0> a L<Locale::Unicode::RBNF::DecimalFormat>.

Rule sets reference one another through substitutions, so the rule set is kept as a weak reference.

=head1 METHODS

=head2 calc_upper_bound

    my $bound = $sub->calc_upper_bound( $old_upper_bound );

Returns the upper bound of the values the substitution can match during a parse. The base implementation returns the bound given.

=head2 compose_rule_value

    my $value = $sub->compose_rule_value( $new, $old );

Combines the value parsed by the substitution, C<$new>, with the value of the rule, C<$old>. The base implementation returns C<$new>.

=head2 do_parse

    my( $success, $value ) = $sub->do_parse( $text, $pp, $base_value, $upper_bound, $lenient, $mask, $rc );

This is ICU C<NFSubstitution::doParse()>: it parses the text with the rule set, or the decimal format, of the substitution, then composes the result with the base value given, with L</compose_rule_value>. It returns a list of 2 elements: whether something was matched, and the value.

This method is provided by L<Locale::Unicode::RBNF::PP>, and used by the pure Perl parsing engine. The classes C<Modulus>, C<FractionalPart> and C<Numerator> have their own version.

=head2 do_substitution_double

    $sub->do_substitution_double( $number, $out, $pos, $rc, $st );

Transforms the number with L</transform_double>, then formats the result into C<$out>, at C<$pos> plus the offset of the substitution: with the rule set, in integer space if the result is an integer, or with the decimal format. An infinite result is formatted with the infinity rule of the rule set.

=head2 do_substitution_int

    $sub->do_substitution_int( $number, $out, $pos, $rc, $st );

The same as L</do_substitution_double>, for an integer, transformed with L</transform_int>. Beyond 2^53, a decimal format formats the integer itself, rather than a double, so that its precision is kept.

=head2 get_pos

Returns the offset of the substitution in the rule text.

=head2 get_rule_set

Returns the rule set used by the substitution, or C<undef> if it uses a decimal format.

=head2 is_modulus

Returns true for a modulus substitution, and false otherwise.

=head2 set_decimal_format_symbols

    $sub->set_decimal_format_symbols( $symbols, \$st );

Passes new decimal format symbols to the decimal format of the substitution, if it has one.

=head2 set_divisor

    $sub->set_divisor( $radix, $exponent, \$st );

Does nothing, except for multiplier and modulus substitutions.

=head2 to_string

Returns the token of the substitution in the ICU syntax, such as C<< <%spellout-cardinal< >> or C<=#,##0=>, built with L</token_char>.

=head2 token_char

Returns the character delimiting the token of the substitution: C<=>, C<< < >> or C<< > >>. Each class defines it.

=head2 transform_double

    my $n = $sub->transform_double( $number );

Returns the value derived from a double that the substitution formats. The base implementation returns the number unchanged.

=head2 transform_int

    my $n = $sub->transform_int( $number );

Returns the value derived from an integer that the substitution formats. The base implementation returns the number unchanged.

=head1 Locale::Unicode::RBNF::Substitution::SameValue

The C<==> substitution: the value is passed through unchanged.

=head2 new

The same as the base L</new>, except that C<==> alone, without a rule set or a decimal format, is an error.

=head2 calc_upper_bound

Returns the bound given.

=head2 compose_rule_value

Returns the value parsed, C<$new>.

=head2 token_char

Returns C<=>.

=head2 transform_double

Returns the number unchanged.

=head2 transform_int

Returns the number unchanged.

=head1 Locale::Unicode::RBNF::Substitution::Multiplier

The C<< << >> substitution of a normal rule: the number is divided by the divisor of the rule, and the quotient is formatted.

=head2 new

    my $sub = Locale::Unicode::RBNF::Substitution::Multiplier->new( $pos, $rule, $rule_set, $token, \$st );

The same as the base L</new>, with the owning rule, from which the divisor is taken, as an additional argument. A divisor of 0 is an error.

=head2 calc_upper_bound

Returns the divisor.

=head2 compose_rule_value

Returns the value parsed, C<$new>, multiplied by the divisor.

=head2 set_divisor

    $sub->set_divisor( $radix, $exponent, \$st );

Sets the divisor to the radix raised to the power of the exponent, as an C<int64_t>. A divisor of 0 is an error.

=head2 token_char

Returns C<< < >>.

=head2 transform_double

Returns the number divided by the divisor, floored. The quotient is not floored when it is formatted with a decimal format, the owning rule has no modulus substitution, and the rounding mode of the formatter is not C<floor>, so that the decimal format can round it.

=head2 transform_int

Returns the number divided by the divisor, truncated towards zero.

=head1 Locale::Unicode::RBNF::Substitution::Modulus

The C<<< >> >>> substitution of a normal rule: the remainder of the division of the number by the divisor of the rule is formatted. With C<<< >>> >>>, the preceding rule is used directly, rather than the rule set.

=head2 new

    my $sub = Locale::Unicode::RBNF::Substitution::Modulus->new( $pos, $rule, $predecessor, $rule_set, $token, \$st );

The same as the base L</new>, with the owning rule, from which the divisor is taken, and the preceding rule, used for C<<< >>> >>>, as additional arguments. A divisor of 0 is an error.

=head2 calc_upper_bound

Returns the divisor.

=head2 compose_rule_value

Returns the value of the rule, C<$old>, less its remainder by the divisor, plus the value parsed, C<$new>.

=head2 do_parse

The same as the base L</do_parse>, except that, with C<<< >>> >>>, the text is parsed with the preceding rule directly. This method is provided by L<Locale::Unicode::RBNF::PP>.

=head2 do_substitution_double

The same as the base L</do_substitution_double>, except that, with C<<< >>> >>>, the remainder is formatted with the preceding rule directly.

=head2 do_substitution_int

The same as the base L</do_substitution_int>, except that, with C<<< >>> >>>, the remainder is formatted with the preceding rule directly.

=head2 is_modulus

Returns true.

=head2 set_divisor

    $sub->set_divisor( $radix, $exponent, \$st );

Sets the divisor to the radix raised to the power of the exponent, as an C<int64_t>. A divisor of 0 is an error.

=head2 to_string

Returns C<<< >>> >>> if the preceding rule is used directly, and otherwise the same as the base L</to_string>.

=head2 token_char

Returns C<< > >>.

=head2 transform_double

Returns the remainder of the division of the number by the divisor, as C<fmod()> does.

=head2 transform_int

Returns the remainder of the division of the number by the divisor, with the sign of the number, as in C.

=head1 Locale::Unicode::RBNF::Substitution::IntegralPart

The C<< << >> substitution of a fraction rule: the integral part of the number is formatted.

=head2 calc_upper_bound

Returns the largest double, since the integral part has no upper bound.

=head2 compose_rule_value

Returns the sum of the value parsed and of the value of the rule.

=head2 token_char

Returns C<< < >>.

=head2 transform_double

Returns the number floored.

=head2 transform_int

Returns the number unchanged.

=head1 Locale::Unicode::RBNF::Substitution::FractionalPart

The C<<< >> >>> substitution of a fraction rule: the fractional part of the number is formatted, either digit by digit with the rule set owning the rule, for C<<< >> >>> and C<<< >>> >>>, or with a fraction rule set, such as with C<< >%%frac> >>.

=head2 new

The same as the base L</new>. With C<<< >> >>>, C<<< >>> >>>, or the rule set owning the rule, the digits are formatted one by one, separated with a space except for C<<< >>> >>>. Otherwise, the rule set given becomes a fraction rule set, with L<Locale::Unicode::RBNF::RuleSet/make_into_fraction_rule_set>.

=head2 calc_upper_bound

Returns 0, which is not used.

=head2 compose_rule_value

Returns the sum of the value parsed and of the value of the rule.

=head2 do_parse

When the digits are formatted one by one, the text is parsed one digit at a time with the rule set, with an upper bound of 10, until the text no longer matches. Otherwise, this is the same as the base L</do_parse>. This method is provided by L<Locale::Unicode::RBNF::PP>.

=head2 do_substitution_double

When the digits are formatted one by one, each digit of the fractional part, including the zeros after the decimal point, is formatted as an integer with the rule set, from the shortest decimal representation of the number rounded to 20 fraction digits; if there is none, C<0> is formatted, so that the result does not end with the word for the decimal point. Otherwise, this is the same as the base L</do_substitution_double>.

=head2 do_substitution_int

Does nothing, as a fractional part substitution has nothing to format for an integer.

=head2 token_char

Returns C<< > >>.

=head2 transform_double

Returns the fractional part of the number.

=head2 transform_int

Returns 0.

=head1 Locale::Unicode::RBNF::Substitution::AbsoluteValue

The C<<< >> >>> substitution of a negative-number rule: the absolute value of the number is formatted.

=head2 calc_upper_bound

Returns the largest double.

=head2 compose_rule_value

Returns the opposite of the value parsed.

=head2 token_char

Returns C<< > >>.

=head2 transform_double

Returns the absolute value of the number.

=head2 transform_int

Returns the absolute value of the number.

=head1 Locale::Unicode::RBNF::Substitution::Numerator

The C<< << >> substitution of a rule in a fraction rule set: the numerator of the fraction whose denominator is the base value of the rule is formatted, with the default rule set of the formatter. When the token ends with C<< << >>, such as in C<< <%%digits<< >>, the leading zeros of the decimal expansion are formatted too.

=head2 new

    my $sub = Locale::Unicode::RBNF::Substitution::Numerator->new( $pos, $denominator, $rule_set, $token, \$st );

The same as the base L</new>, with the denominator as an additional argument, and the default rule set of the formatter as the rule set. Without a rule set, this is an error.

=head2 calc_upper_bound

Returns the denominator.

=head2 compose_rule_value

Returns the value parsed divided by the value of the rule. As in C++, a division by 0 yields an infinity, or C<NaN> for 0 divided by 0.

=head2 do_parse

The same as the base L</do_parse>, without lenient matching, which does not suit the algorithm, and, with leading zeros, counting the zeros parsed first. This method is provided by L<Locale::Unicode::RBNF::PP>.

=head2 do_substitution_double

Formats the numerator, preceded by the leading zeros when they are requested, each zero preceded by a space.

=head2 do_substitution_int

Does nothing, as a numerator substitution has nothing to format for an integer.

=head2 token_char

Returns C<< < >>.

=head2 transform_double

Returns the number multiplied by the denominator, rounded to the nearest integer.

=head2 transform_int

Returns the number multiplied by the denominator.

=head1 SEE ALSO

L<Locale::Unicode::RBNF>, L<Locale::Unicode::RBNF::Rule>, L<Locale::Unicode::RBNF::RuleSet>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

Portions are derived from ICU, Copyright (C) 2016 and later Unicode, Inc. and others, under the Unicode License (L<https://www.unicode.org/copyright.html>). Its text is in the F<LICENSE-UNICODE> file of this distribution.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
