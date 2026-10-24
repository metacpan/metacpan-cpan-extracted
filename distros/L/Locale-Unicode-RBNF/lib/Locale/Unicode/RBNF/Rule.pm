##----------------------------------------------------------------------------
## Unicode Rule-Based Number Format - ~/lib/Locale/Unicode/RBNF/Rule.pm
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
# Port of ICU4C NFRule (icu4c/source/i18n/nfrule.cpp, ICU 79.1)
package Locale::Unicode::RBNF::Rule;
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
    use vars qw( $VERSION @RULE_PREFIXES );
    use POSIX ();
    use Scalar::Util qw( weaken );
    use Unicode::Normalize ();
    use Unicode::UCD ();
    use Locale::Unicode::RBNF::Substitution;
    use Locale::Unicode::RBNF::Util qw( :all );
    use constant {
        NO_BASE             => 0,
        NEGATIVE_NUMBER     => -1,
        IMPROPER_FRACTION   => -2,
        PROPER_FRACTION     => -3,
        DEFAULT_RULE        => -4,
        INFINITY_RULE       => -5,
        NAN_RULE            => -6,
        OTHER_RULE          => -7,
    };
    @RULE_PREFIXES = ( '<<', '<%', '<#', '<0', '>>', '>%', '>#', '>0', '=%', '=#', '=0' );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

{
    no warnings 'once';
    $Locale::Unicode::RBNF::IsPurePerl //= 1;
}

# Caches for the lenient matching: simple case folding (keyed by the Turkic flag, then by the
# character), NFC boundaries and separators. These functions are also called by the C engine.
my $FOLD_CACHE = {};
my $BOUNDARY_CACHE = {};
my $SEPARATOR_CACHE = {};

sub new
{
    my( $this, $rbnf, $text, $st ) = @_;
    my $self = bless(
    {
        base_value      => 0,
        radix           => 10,
        exponent        => 0,
        divisor         => 1,
        decimal_point   => '',
        rule_text       => $text // '',
        sub1            => undef,
        sub2            => undef,
        formatter       => $rbnf,
        plural_format   => undef,
    }, ( ref( $this ) || $this ) );
    weaken( $self->{formatter} );
    $self->_parse_rule_descriptor( \$self->{rule_text}, $st ) if( length( $self->{rule_text} ) );
    return( $self );
}

# Insert the rule text, then the substitutions in reverse order so that offsets remain valid.
sub do_format_double
{
    my( $self, $number, $out, $pos, $rc, $st ) = @_;
    my( $plural_start, $length_offset ) = $self->_insert_rule_text( $number, 1, $out, $pos, $st );
    if( my $sub = $self->{sub2} )
    {
        $sub->do_substitution_double( $number, $out, $pos - ( $sub->{pos} > $plural_start ? $length_offset : 0 ), $rc, $st );
    }
    if( my $sub = $self->{sub1} )
    {
        $sub->do_substitution_double( $number, $out, $pos - ( $sub->{pos} > $plural_start ? $length_offset : 0 ), $rc, $st );
    }
    return;
}

sub do_format_int
{
    my( $self, $number, $out, $pos, $rc, $st ) = @_;
    my( $plural_start, $length_offset ) = $self->_insert_rule_text( $number, 0, $out, $pos, $st );
    if( my $sub = $self->{sub2} )
    {
        $sub->do_substitution_int( $number, $out, $pos - ( $sub->{pos} > $plural_start ? $length_offset : 0 ), $rc, $st );
    }
    if( my $sub = $self->{sub1} )
    {
        $sub->do_substitution_int( $number, $out, $pos - ( $sub->{pos} > $plural_start ? $length_offset : 0 ), $rc, $st );
    }
    return;
}

sub get_base_value { return( $_[0]->{base_value} ); }

sub get_decimal_point { return( $_[0]->{decimal_point} ); }

sub get_divisor { return( $_[0]->{divisor} ); }

sub get_type { return( $_[0]->{base_value} <= NO_BASE ? $_[0]->{base_value} : OTHER_RULE ); }

sub has_modulus_substitution
{
    my $self = shift( @_ );
    return( ( $self->{sub1} && $self->{sub1}->is_modulus ) || ( $self->{sub2} && $self->{sub2}->is_modulus ) ? 1 : 0 );
}

# NFRule::makeRules(): creates one or two rules from a description, depending on whether it
# contains bracketed optional text, and adds them to the rule list or the owner's special rules.
sub make_rules
{
    my( $class, $description, $owner, $predecessor, $rbnf, $rules, $st ) = @_;
    return if( $$st );
    my $rule1 = $class->new( $rbnf, $description, $st );
    return if( $$st );
    $description = $rule1->{rule_text};
    my $brack1 = index( $description, '[' );
    my $brack2 = $brack1 < 0 ? -1 : index( $description, ']' );
    my $type = $rule1->get_type;
    if( $brack2 < 0 || $brack1 > $brack2 ||
        $type == PROPER_FRACTION ||
        $type == NEGATIVE_NUMBER ||
        $type == INFINITY_RULE ||
        $type == NAN_RULE )
    {
        $rule1->_extract_substitutions( $owner, $description, $predecessor, $st );
        return if( $$st );
    }
    else
    {
        # A matched pair of brackets is shorthand for two rules (with one exception).
        my $rule2;
        my $or_else = index( $description, '|' );
        my $mod = pow_u64( $rule1->{radix}, $rule1->{exponent} );
        if( $rule1->{base_value} > 0 && $rule1->{radix} != 0 && $mod == 0 )
        {
            $$st = 'U_NUMBER_ARG_OUTOFBOUNDS_ERROR';
            return;
        }
        # The base value is an int64 and the modulus a uint64, so the comparison is unsigned.
        my $even = 0;
        if( $rule1->{base_value} > 0 && $rule1->{radix} != 0 )
        {
            $even = ( $mod > $Locale::Unicode::RBNF::Util::INT64_MAX ? $rule1->{base_value} : imod( $rule1->{base_value}, $mod ) ) == 0 ? 1 : 0;
        }
        if( $even || $type == IMPROPER_FRACTION || $type == DEFAULT_RULE )
        {
            # rule1 actually goes SECOND in the rule set's rule list
            $rule2 = $class->new( $rbnf, '', $st );
            return if( $$st );
            if( $rule1->{base_value} >= 0 )
            {
                $rule2->{base_value} = $rule1->{base_value};
                ++$rule1->{base_value} if( !$owner->is_fraction_rule_set );
            }
            elsif( $type == IMPROPER_FRACTION )
            {
                # "x.x" with brackets describes both the improper and the proper fraction rule.
                $rule2->{base_value} = PROPER_FRACTION;
            }
            elsif( $type == DEFAULT_RULE )
            {
                # "x.0" with brackets describes both the default and the improper fraction rule.
                $rule2->{base_value} = $rule1->{base_value};
                $rule1->{base_value} = IMPROPER_FRACTION;
            }
            # Both rules have the same radix and exponent, that is the same divisor.
            $rule2->{radix} = $rule1->{radix};
            $rule2->{exponent} = $rule1->{exponent};
            $rule2->_update_divisor;
            # rule2's text omits the bracketed text, unless it contains a | between the brackets.
            my $sbuf = _sub( $description, 0, $brack1 );
            $sbuf .= _sub( $description, $or_else + 1, $brack2 - $or_else - 1 ) if( $or_else >= 0 );
            $sbuf .= _sub( $description, $brack2 + 1, length( $description ) - $brack2 - 1 ) if( $brack2 + 1 < length( $description ) );
            $rule2->_extract_substitutions( $owner, $sbuf, $predecessor, $st );
            return if( $$st );
        }
        # rule1's text includes the text in the brackets but omits the brackets themselves.
        my $sbuf = _sub( $description, 0, $brack1 );
        if( $or_else >= 0 )
        {
            $sbuf .= _sub( $description, $brack1 + 1, $or_else - $brack1 - 1 );
        }
        else
        {
            $sbuf .= _sub( $description, $brack1 + 1, $brack2 - $brack1 - 1 );
        }
        $sbuf .= _sub( $description, $brack2 + 1, length( $description ) - $brack2 - 1 ) if( $brack2 + 1 < length( $description ) );
        $rule1->_extract_substitutions( $owner, $sbuf, $predecessor, $st );
        return if( $$st );
        if( $rule2 )
        {
            if( $rule2->{base_value} >= NO_BASE ) { push( @$rules, $rule2 ); }
            else { $owner->set_non_numerical_rule( $rule2 ); }
        }
    }
    if( $rule1->{base_value} >= NO_BASE ) { push( @$rules, $rule1 ); }
    else { $owner->set_non_numerical_rule( $rule1 ); }
    return;
}

sub set_base_value
{
    my( $self, $value, $st ) = @_;
    $self->{base_value} = $value;
    $self->{radix} = 10;
    if( $value >= 1 )
    {
        $self->{exponent} = $self->_expected_exponent;
        $self->_update_divisor;
        # This rule may already hold substitutions keeping a copy of the divisor.
        $self->{sub1}->set_divisor( $self->{radix}, $self->{exponent}, $st ) if( $self->{sub1} );
        $self->{sub2}->set_divisor( $self->{radix}, $self->{exponent}, $st ) if( $self->{sub2} );
    }
    else
    {
        $self->{exponent} = 0;
        $self->_update_divisor;
    }
    return;
}

sub set_decimal_format_symbols
{
    my( $self, $symbols, $st ) = @_;
    $self->{sub1}->set_decimal_format_symbols( $symbols, $st ) if( $self->{sub1} );
    $self->{sub2}->set_decimal_format_symbols( $symbols, $st ) if( $self->{sub2} );
    return;
}

# The rollback rule: for "100: << hundred[ >>];" the rule at 101 must not be used for 200,
# otherwise we would get "two hundred zero".
sub should_roll_back
{
    my( $self, $number ) = @_;
    if( $self->{radix} != 0 && $self->has_modulus_substitution )
    {
        my $re = $self->{divisor};
        return(0) if( !$re );
        return( imod( $number, $re ) == 0 && imod( $self->{base_value}, $re ) != 0 ? 1 : 0 );
    }
    return(0);
}

# NFRule::_appendRuleText(), used by Locale::Unicode::RBNF->rules
sub to_string
{
    my $self = shift( @_ );
    my $type = $self->get_type;
    my $dp = length( $self->{decimal_point} ) ? $self->{decimal_point} : '.';
    my $result = '';
    if( $type == NEGATIVE_NUMBER ) { $result .= '-x'; }
    elsif( $type == IMPROPER_FRACTION ) { $result .= "x${dp}x"; }
    elsif( $type == PROPER_FRACTION ) { $result .= "0${dp}x"; }
    elsif( $type == DEFAULT_RULE ) { $result .= "x${dp}0"; }
    elsif( $type == INFINITY_RULE ) { $result .= 'Inf'; }
    elsif( $type == NAN_RULE ) { $result .= 'NaN'; }
    else
    {
        $result .= $self->{base_value};
        $result .= '/' . $self->{radix} if( $self->{radix} != 10 );
        my $carets = $self->_expected_exponent - $self->{exponent};
        $result .= '>' x $carets if( $carets > 0 );
    }
    $result .= ': ';
    # Whitespace after the rule descriptor is ignored, so an apostrophe makes it significant.
    $result .= "'" if( substr( $self->{rule_text}, 0, 1 ) eq ' ' && ( !$self->{sub1} || $self->{sub1}->{pos} != 0 ) );
    my $copy = $self->{rule_text};
    substr( $copy, $self->{sub2}->{pos}, 0, $self->{sub2}->to_string ) if( $self->{sub2} );
    substr( $copy, $self->{sub1}->{pos}, 0, $self->{sub1}->to_string ) if( $self->{sub1} );
    return( $result . $copy . ';' );
}

sub _expected_exponent
{
    my $self = shift( @_ );
    # The log of 0, or the log base 0 of something, is an error, so the exponent is 0 then.
    return(0) if( $self->{radix} == 0 || $self->{base_value} < 1 );
    # A radix of 1 makes log( radix ) 0, which is undefined behaviour in C++ and fatal in Perl.
    return(0) if( $self->{radix} == 1 );
    # log 1000 / log 10 gives 2.9999999996 instead of 3, so we check the next power.
    my $t = int( log( $self->{base_value} ) / log( $self->{radix} ) );
    my $temp = to_i64( pow_u64( $self->{radix}, $t + 1 ) );
    $t += 1 if( $temp <= $self->{base_value} );
    return( $t );
}

sub _extract_substitution
{
    my( $self, $owner, $predecessor, $st ) = @_;
    my $sub_start = $self->_index_of_any_rule_prefix;
    return if( $sub_start == -1 );
    my $sub_end;
    my $text = $self->{rule_text};
    # Special case for the ">>>" token, since searching for the > at the end would find the
    # one in the middle.
    if( index( $text, '>>>' ) == $sub_start )
    {
        $sub_end = $sub_start + 2;
    }
    else
    {
        my $c = substr( $text, $sub_start, 1 );
        $sub_end = index( $text, $c, $sub_start + 1 );
        # Special case for '<%foo<<'
        if( $c eq '<' && $sub_end != -1 && $sub_end < length( $text ) - 1 && substr( $text, $sub_end + 1, 1 ) eq $c )
        {
            ++$sub_end;
        }
    }
    return if( $sub_end == -1 );
    my $token = substr( $text, $sub_start, $sub_end + 1 - $sub_start );
    my $result = Locale::Unicode::RBNF::Substitution->make( $sub_start, $self, $predecessor, $owner, $self->{formatter}, $token, $st );
    substr( $self->{rule_text}, $sub_start, $sub_end + 1 - $sub_start, '' );
    return( $result );
}

sub _extract_substitutions
{
    my( $self, $owner, $source, $predecessor, $st ) = @_;
    return if( $$st );
    $self->{rule_text} = $source;
    $self->{sub1} = $self->_extract_substitution( $owner, $predecessor, $st );
    $self->{sub2} = $self->{sub1} ? $self->_extract_substitution( $owner, $predecessor, $st ) : undef;
    if( $self->{sub1} && $self->{sub2} && ref( $self->{sub1} ) eq ref( $self->{sub2} ) )
    {
        # Something like << << or >> >> or == == was encountered. ICU only issues a warning
        # (U_STATE_OLD_WARNING) and marks the formatter as unparseable.
        $self->{formatter}->{unparseable} = 1 if( $self->{formatter} );
    }
    my $text = $self->{rule_text};
    my $plural_start = index( $text, '$(' );
    my $plural_end = $plural_start >= 0 ? index( $text, ')$', $plural_start ) : -1;
    if( $plural_end >= 0 )
    {
        my $end_type = index( $text, ',', $plural_start );
        if( $end_type < 0 )
        {
            $$st = 'U_PARSE_ERROR: missing plural type in rule text "' . $text . '"';
            return;
        }
        my $type = substr( $text, $plural_start + 2, $end_type - $plural_start - 2 );
        my $plural_type;
        if( index( $type, 'cardinal' ) == 0 ) { $plural_type = 'cardinal'; }
        elsif( index( $type, 'ordinal' ) == 0 ) { $plural_type = 'ordinal'; }
        else
        {
            $$st = 'U_ILLEGAL_ARGUMENT_ERROR: unknown plural type "' . $type . '"';
            return;
        }
        $self->{plural_format} = $self->{formatter}->_create_plural_format( $plural_type, _sub( $text, $end_type + 1, $plural_end - $end_type - 1 ), $st );
    }
    return;
}

sub _fold_case
{
    my( $c, $turkic ) = @_;
    my $cache = ( $FOLD_CACHE->{ $turkic ? 1 : 0 } //= {} );
    return( $cache->{ $c } ) if( exists( $cache->{ $c } ) );
    my $fold = $c;
    # ICU folds UTF-16 code units, and a surrogate has no case mapping, so characters outside
    # the BMP are never folded.
    my $info = ord( $c ) > 0xFFFF ? undef : Unicode::UCD::casefold( ord( $c ) );
    if( $info )
    {
        # u_foldCase() is the simple, one-to-one case folding. U_FOLD_CASE_EXCLUDE_SPECIAL_I
        # selects the Turkic mappings for dotted and dotless i.
        my $map = ( $turkic && length( $info->{turkic} // '' ) ) ? $info->{turkic} : $info->{simple};
        $map = $info->{mapping} if( !length( $map // '' ) && ( $info->{status} // '' ) =~ /^[CS]$/ );
        $fold = join( '', map( chr( hex( $_ ) ), split( / /, $map ) ) ) if( length( $map // '' ) );
    }
    return( $cache->{ $c } = $fold );
}

# Normalizer2::hasBoundaryBefore() for NFC
sub _has_nfc_boundary_before
{
    my $c = shift( @_ );
    return( $BOUNDARY_CACHE->{ $c } ) if( exists( $BOUNDARY_CACHE->{ $c } ) );
    my $cp = ord( $c );
    my $result = 1;
    if( Unicode::Normalize::getCombinClass( $cp ) != 0 || Unicode::Normalize::isComp2nd( $cp ) )
    {
        $result = 0;
    }
    else
    {
        my $decomp = Unicode::Normalize::getCanon( $cp );
        $result = 0 if( defined( $decomp ) && length( $decomp ) && Unicode::Normalize::getCombinClass( ord( $decomp ) ) != 0 );
    }
    return( $BOUNDARY_CACHE->{ $c } = $result );
}

sub _index_of_any_rule_prefix
{
    my $self = shift( @_ );
    my $result = -1;
    foreach my $prefix ( @RULE_PREFIXES )
    {
        my $pos = index( $self->{rule_text}, $prefix );
        $result = $pos if( $pos != -1 && ( $result == -1 || $pos < $result ) );
    }
    return( $result );
}

# Inserts the rule text, resolving a plural pattern if any. Returns the plural start and the
# length offset that the substitutions need to correct their insertion positions.
sub _insert_rule_text
{
    my( $self, $number, $is_double, $out, $pos, $st ) = @_;
    my $text = $self->{rule_text};
    my $plural_start = length( $text );
    my $length_offset = 0;
    if( !$self->{plural_format} )
    {
        str_insert( $out, $pos, $text );
        return( $plural_start, $length_offset );
    }
    $plural_start = index( $text, '$(' );
    my $plural_end = index( $text, ')$', $plural_start );
    my $initial_length = length( $$out );
    str_insert( $out, $pos, substr( $text, $plural_end + 2 ) ) if( $plural_end < length( $text ) - 1 );
    my $plural_val;
    if( $is_double )
    {
        $plural_val = $number;
        # In a fractional rule we must match the NumeratorSubstitution behaviour:
        # 2.3 can become 0.2999999999999998 for the fraction due to rounding errors.
        if( $plural_val >= 0 && $plural_val < 1 )
        {
            $plural_val = POSIX::floor( $plural_val * pow_u64( $self->{radix}, $self->{exponent} ) + 0.5 );
        }
        else
        {
            $plural_val = $plural_val / pow_u64( $self->{radix}, $self->{exponent} );
        }
        $plural_val = dbl_to_i32( $plural_val );
    }
    else
    {
        my $div = to_i64( pow_u64( $self->{radix}, $self->{exponent} ) );
        $plural_val = to_i32( $div ? idiv( $number, $div ) : 0 );
    }
    str_insert( $out, $pos, $self->{plural_format}->format( $plural_val, $st ) );
    str_insert( $out, $pos, substr( $text, 0, $plural_start ) ) if( $plural_start > 0 );
    $length_offset = length( $text ) - ( length( $$out ) - $initial_length );
    return( $plural_start, $length_offset );
}

sub _parse_rule_descriptor
{
    my( $self, $desc_ref, $st ) = @_;
    my $p = index( $$desc_ref, ':' );
    if( $p != -1 )
    {
        my $descriptor = substr( $$desc_ref, 0, $p );
        ++$p;
        ++$p while( $p < length( $$desc_ref ) && is_pattern_ws( substr( $$desc_ref, $p, 1 ) ) );
        substr( $$desc_ref, 0, $p, '' );

        my $dlen = length( $descriptor );
        my $first = $dlen ? substr( $descriptor, 0, 1 ) : '';
        my $last = $dlen ? substr( $descriptor, -1 ) : '';
        if( $first =~ /^[0-9]$/ && $last ne 'x' )
        {
            # A descriptor beginning with a digit is the one of a normal rule: digits are
            # accumulated, periods, commas and spaces are skipped, and a slash or > stops it.
            my $val = 0;
            my $c = '';
            $p = 0;
            while( $p < $dlen )
            {
                $c = substr( $descriptor, $p, 1 );
                if( $c =~ /^[0-9]$/ )
                {
                    if( $val > 0 && $val > idiv( $Locale::Unicode::RBNF::Util::INT64_MAX - $c, 10 ) )
                    {
                        $$st = 'U_PARSE_ERROR: base value out of int64 range in "' . $descriptor . '"';
                        return;
                    }
                    $val = $val * 10 + $c;
                }
                elsif( $c eq '/' || $c eq '>' )
                {
                    last;
                }
                elsif( is_pattern_ws( $c ) || $c eq ',' || $c eq '.' )
                {
                }
                else
                {
                    $$st = 'U_PARSE_ERROR: illegal character in rule descriptor "' . $descriptor . '"';
                    return;
                }
                ++$p;
            }
            $self->set_base_value( $val, $st );

            # A slash introduces the radix.
            if( $c eq '/' )
            {
                $val = 0;
                ++$p;
                while( $p < $dlen )
                {
                    $c = substr( $descriptor, $p, 1 );
                    if( $c =~ /^[0-9]$/ )
                    {
                        if( $val > 0 && $val > idiv( $Locale::Unicode::RBNF::Util::INT64_MAX - $c, 10 ) )
                        {
                            $$st = 'U_PARSE_ERROR: radix out of int64 range in "' . $descriptor . '"';
                            return;
                        }
                        $val = $val * 10 + $c;
                    }
                    elsif( $c eq '>' )
                    {
                        last;
                    }
                    elsif( is_pattern_ws( $c ) || $c eq ',' || $c eq '.' )
                    {
                    }
                    else
                    {
                        $$st = 'U_PARSE_ERROR: illegal character in rule descriptor "' . $descriptor . '"';
                        return;
                    }
                    ++$p;
                }
                # ICU stores the radix in an int32_t.
                $self->{radix} = to_i32( $val );
                # ICU sets the error but carries on, so we do the same.
                $$st = 'U_PARSE_ERROR: rule cannot have a radix of 0' if( $self->{radix} == 0 );
                $self->{exponent} = $self->_expected_exponent;
                $self->_update_divisor;
            }

            # Each > sign decrements the exponent, unless it is already 0.
            if( $c eq '>' )
            {
                while( $p < $dlen )
                {
                    $c = substr( $descriptor, $p, 1 );
                    if( $c eq '>' && $self->{exponent} > 0 )
                    {
                        --$self->{exponent};
                    }
                    else
                    {
                        $$st = 'U_PARSE_ERROR: illegal character in rule descriptor "' . $descriptor . '"';
                        return;
                    }
                    ++$p;
                }
                $self->_update_divisor;
            }
        }
        elsif( $descriptor eq '-x' )
        {
            $self->{base_value} = NEGATIVE_NUMBER;
        }
        elsif( $dlen == 3 )
        {
            if( $first eq '0' && $last eq 'x' )
            {
                $self->set_base_value( PROPER_FRACTION, $st );
                $self->{decimal_point} = substr( $descriptor, 1, 1 );
            }
            elsif( $first eq 'x' && $last eq 'x' )
            {
                $self->set_base_value( IMPROPER_FRACTION, $st );
                $self->{decimal_point} = substr( $descriptor, 1, 1 );
            }
            elsif( $first eq 'x' && $last eq '0' )
            {
                $self->set_base_value( DEFAULT_RULE, $st );
                $self->{decimal_point} = substr( $descriptor, 1, 1 );
            }
            elsif( $descriptor eq 'NaN' )
            {
                $self->set_base_value( NAN_RULE, $st );
            }
            elsif( $descriptor eq 'Inf' )
            {
                $self->set_base_value( INFINITY_RULE, $st );
            }
        }
    }
    # A leading apostrophe is stripped; it is used to put whitespace at the beginning of a rule.
    substr( $$desc_ref, 0, 1, '' ) if( length( $$desc_ref ) && substr( $$desc_ref, 0, 1 ) eq "'" );
    return;
}

sub _update_divisor
{
    my $self = shift( @_ );
    $self->{divisor} = to_i64( pow_u64( $self->{radix}, $self->{exponent} ) );
    return;
}

# Zs (space separators), Pd (dash punctuation), Cf (format characters), plus comma and period.
# ICU tests UTF-16 code units, so a character outside the BMP, seen as surrogates, never is one.
sub _is_lenient_separator
{
    my $c = shift( @_ );
    return( $SEPARATOR_CACHE->{ $c } //= ( ( ord( $c ) <= 0xFFFF && $c =~ /\A[\p{Zs}\p{Pd}\p{Cf},.]\z/ ) ? 1 : 0 ) );
}

# Substring with pinned indices, as UnicodeString::compare( start, length, ... ) does.
sub _pinned
{
    my( $str, $start, $len ) = @_;
    my $slen = length( $str );
    $start = 0 if( $start < 0 );
    $start = $slen if( $start > $slen );
    $len = 0 if( $len < 0 );
    $len = $slen - $start if( $len > $slen - $start );
    return( substr( $str, $start, $len ) );
}

# Substring as UnicodeString::append( src, start, length ) does: pinned, and empty when the
# length is negative.
sub _sub
{
    my( $str, $start, $len ) = @_;
    return( '' ) if( !defined( $len ) || $len <= 0 );
    return( _pinned( $str, $start, $len ) );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Locale::Unicode::RBNF::Rule - A single rule of a rule-based number format

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Internal module. This is a port of ICU4C C<NFRule> (F<nfrule.cpp>, ICU 79.1).

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

=head1 CONSTANTS

The rule types, which are also the base values of the non-numerical rules, as in ICU C<NFRule>:

=over 4

=item * C<NO_BASE> (0)

=item * C<NEGATIVE_NUMBER> (-1), the C<-x> rule

=item * C<IMPROPER_FRACTION> (-2), the C<x.x> rule

=item * C<PROPER_FRACTION> (-3), the C<0.x> rule

=item * C<DEFAULT_RULE> (-4), the C<x.0> rule

=item * C<INFINITY_RULE> (-5), the C<Inf> rule

=item * C<NAN_RULE> (-6), the C<NaN> rule

=item * C<OTHER_RULE> (-7), returned by L</get_type> for a normal rule

=back

The variable C<@RULE_PREFIXES> holds the tokens that start a substitution: C<< << >>, C<< <% >>, C<< <# >>, C<< <0 >>, C<< >> >>, C<< >% >>, C<< ># >>, C<< >0 >>, C<=%>, C<=#> and C<=0>.

=head1 CONSTRUCTOR

=head2 new

    my $rule = Locale::Unicode::RBNF::Rule->new( $formatter, $description, \$st );

Takes the L<Locale::Unicode::RBNF> object that owns the rule, the description of a single rule, and a scalar reference that receives an error status. The rule descriptor, the part before the colon, such as C<100>, C<1000/1000>, C<< 100>> >>, C<-x>, C<x.x> or C<Inf>, is parsed, and removed from the rule text.

The formatter is kept as a weak reference. Rules are normally created with L</make_rules>, which also extracts the substitutions.

=head1 METHODS

=head2 do_format_double

    $rule->do_format_double( $number, $out, $pos, $rc, $st );

This is ICU C<NFRule::doFormat()> for a double: it inserts the rule text, with any plural sub-message resolved for the number, into C<$out> at C<$pos>, then lets each substitution format its part of the number, the second substitution first, so that the offsets remain valid.

=head2 do_format_int

    $rule->do_format_int( $number, $out, $pos, $rc, $st );

The same as L</do_format_double>, for an integer.

=head2 do_parse

    my( $success, $value ) = $rule->do_parse( $text, $pp, $is_fraction_rule, $upper_bound, $mask, $rc );

This is ICU C<NFRule::doParse()>: it matches the text against the rule text and its substitutions, and returns a list of 2 elements: whether something was matched, and the value parsed. C<< $pp->{index} >> is set to the number of characters matched.

This method is provided by L<Locale::Unicode::RBNF::PP>, and used by the pure Perl parsing engine.

=head2 get_base_value

Returns the base value of the rule, or, for a non-numerical rule, its type; see L</CONSTANTS>.

=head2 get_decimal_point

Returns the decimal point character of a fraction rule, such as C<.> in C<x.x> or C<,> in C<x,x>, or an empty string if there is none.

=head2 get_divisor

Returns the divisor of the rule, that is the radix raised to the power of the exponent, as an C<int64_t>.

=head2 get_type

Returns the base value for a non-numerical rule, and C<OTHER_RULE> for a normal rule.

=head2 has_modulus_substitution

Returns true if one of the substitutions of the rule is a modulus substitution (C<<< >> >>>).

=head2 make_rules

    Locale::Unicode::RBNF::Rule->make_rules( $description, $rule_set, $predecessor, $formatter, \@rules, \$st );

This is ICU C<NFRule::makeRules()>: it creates the rule, or, if the description contains bracketed optional text, the two rules it stands for, extracts their substitutions, and adds them to the array reference C<\@rules>, or, for a non-numerical rule, to the special rules of the rule set C<$rule_set> with L<Locale::Unicode::RBNF::RuleSet/set_non_numerical_rule>.

C<$predecessor> is the previous rule of the rule set, used by C<<< >>> >>> substitutions. It returns nothing; errors are reported in C<$st>.

=head2 set_base_value

    $rule->set_base_value( $value, \$st );

Sets the base value of the rule, resets the radix to 10, computes the exponent and the divisor, and updates the divisor of the substitutions. This is used by the rule set for rules that have no explicit base value.

=head2 set_decimal_format_symbols

    $rule->set_decimal_format_symbols( $symbols, \$st );

Passes new decimal format symbols to the substitutions of the rule.

=head2 should_roll_back

    my $bool = $rule->should_roll_back( $number );

Returns true if the preceding rule must be used instead of this one for the number. For a rule such as C<< 100: << hundred[ >>]; >>, the rule at 101 must not be used for 200, otherwise the result would be "two hundred zero".

=head2 to_string

Returns the description of the rule in the ICU syntax, terminated with a semicolon, as ICU C<NFRule::_appendRuleText()> produces it. This is used by L<Locale::Unicode::RBNF/rules>.

=head1 SEE ALSO

L<Locale::Unicode::RBNF>, L<Locale::Unicode::RBNF::RuleSet>, L<Locale::Unicode::RBNF::Substitution>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

Portions are derived from ICU, Copyright (C) 2016 and later Unicode, Inc. and others, under the Unicode License (L<https://www.unicode.org/copyright.html>). Its text is in the F<LICENSE-UNICODE> file of this distribution.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
