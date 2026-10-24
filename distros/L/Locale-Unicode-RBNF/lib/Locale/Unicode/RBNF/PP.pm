##----------------------------------------------------------------------------
## Unicode Rule-Based Number Format - ~/lib/Locale/Unicode/RBNF/PP.pm
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
# Pure-Perl fallback implementations of the parsing code path, which is otherwise
# provided by the Locale::Unicode::RBNF XS layer. Loaded automatically by
# Locale::Unicode::RBNF when XSLoader fails, such as during development or on platforms
# without a C compiler, or when PERL_LOCALE_UNICODE_RBNF_PP is set.
#
# This is the port of the parse code paths of ICU4C 79.1: NFRuleSet::parse,
# NFRule::doParse, NFRule::matchToDelimiter, NFRule::findText, NFRule::findTextLenient, 
# NFRule::prefixLength, NFSubstitution::doParse and its overrides, and
# PluralFormat::parseType, plus the parsing of decimal formats.
#
# Each sub is injected directly into the namespace of the class it belongs to at the
# end of this file, so callers see them as methods.
##----------------------------------------------------------------------------
package Locale::Unicode::RBNF::PP;
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
    use vars qw( $VERSION );
    use POSIX ();
    use Unicode::Normalize ();
    # The classes whose parsing methods are installed at the end of this file
    use Locale::Unicode::RBNF::DecimalFormat ();
    use Locale::Unicode::RBNF::PluralFormat ();
    use Locale::Unicode::RBNF::Rule ();
    use Locale::Unicode::RBNF::RuleSet ();
    use Locale::Unicode::RBNF::Substitution ();
    use Locale::Unicode::RBNF::Util qw( :all );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

# Prepared rule text prefixes for the lenient matching, keyed by the Turkic flag, then
# by the prefix.
my $PREFIX_CACHE = {};

# Parses a number at $pp->{index}. On success the index is moved past the number,
# otherwise it is left unchanged and the error index is set. Returns the value.
sub decimal_format_parse
{
    my( $self, $text, $pp ) = @_;
    my $sym = $self->{symbols};
    my $start = $pp->{index} // 0;
    my $i = $start;
    my $len = length( $text );
    my $neg = 0;
    my $pos = $self->{positive};
    my $negp = $self->{negative};
    my $suffix = $pos->{suffix};
    if( $negp && length( $negp->{prefix} ) && substr( $text, $i, length( $negp->{prefix} ) ) eq $negp->{prefix} )
    {
        $neg = 1;
        $i += length( $negp->{prefix} );
        $suffix = $negp->{suffix};
    }
    elsif( length( $pos->{prefix} ) && substr( $text, $i, length( $pos->{prefix} ) ) eq $pos->{prefix} )
    {
        $i += length( $pos->{prefix} );
    }
    elsif( $i < $len && ( substr( $text, $i, length( $sym->{minus} ) ) eq $sym->{minus} || substr( $text, $i, 1 ) =~ /^[\-\x{2212}]$/ ) )
    {
        $neg = 1;
        $i += substr( $text, $i, length( $sym->{minus} ) ) eq $sym->{minus} ? length( $sym->{minus} ) : 1;
    }
    if( length( $sym->{infinity} ) && substr( $text, $i, length( $sym->{infinity} ) ) eq $sym->{infinity} )
    {
        $pp->{index} = $i + length( $sym->{infinity} );
        return( $neg ? -9**9**9 : 9**9**9 );
    }
    my $int = '';
    my $frac = '';
    my $group = $sym->{group};
    my $group_is_space = ( length( $group ) && $group =~ /^\p{Zs}$/ ) ? 1 : 0;
    while( $i < $len )
    {
        my $c = substr( $text, $i, 1 );
        my $v = Locale::Unicode::RBNF::DecimalFormat::_digit_value( $c );
        if( defined( $v ) )
        {
            $int .= $v;
            $i++;
            next;
        }
        # A grouping separator is accepted between digits only.
        if( length( $int ) && $self->{grouping} && ( $c eq $group || ( $group_is_space && $c =~ /^\p{Zs}$/ ) ) && $i + 1 < $len && defined( Locale::Unicode::RBNF::DecimalFormat::_digit_value( substr( $text, $i + 1, 1 ) ) ) )
        {
            $i++;
            next;
        }
        last;
    }
    if( $i < $len && substr( $text, $i, length( $sym->{decimal} ) ) eq $sym->{decimal} && $i + length( $sym->{decimal} ) < $len && defined( Locale::Unicode::RBNF::DecimalFormat::_digit_value( substr( $text, $i + length( $sym->{decimal} ), 1 ) ) ) )
    {
        $i += length( $sym->{decimal} );
        while( $i < $len )
        {
            my $v = Locale::Unicode::RBNF::DecimalFormat::_digit_value( substr( $text, $i, 1 ) );
            last if( !defined( $v ) );
            $frac .= $v;
            $i++;
        }
    }
    if( !length( $int ) && !length( $frac ) )
    {
        $pp->{error} = $start;
        return(0);
    }
    $i += length( $suffix ) if( length( $suffix ) && substr( $text, $i, length( $suffix ) ) eq $suffix );
    $pp->{index} = $i;
    my $value;
    $int = '0' if( !length( $int ) );
    ( my $significant = $int ) =~ s/^0+//;
    if( length( $frac ) || length( $significant ) > 18 )
    {
        $value = ( $int . ( length( $frac ) ? '.' . $frac : '' ) ) + 0;
    }
    else
    {
        $value = int( $int );
    }
    $value = $value / ( 10 ** $self->{multiplier_exp} ) if( $self->{multiplier_exp} );
    return( $neg ? -$value : $value );
}

sub fractional_part_do_parse
{
    my( $self, $text, $parse_pos, $base_value, $upper_bound, $lenient, $mask, $rc ) = @_;
    return( Locale::Unicode::RBNF::Substitution::do_parse( $self, $text, $parse_pos, $base_value, 0, $lenient, $mask, $rc ) ) if( !$self->{by_digits} );
    # In "by digits" mode, the text is parsed one digit at a time with the owning rule set,
    # using an upper bound of 10, until we reach text that does not match.
    my $work = $text;
    my $work_pos = { index => 1, error => -1 };
    my $digits = '';
    my $value = 0;
    my $total = 0;
    my $fmt;
    while( length( $work ) && $work_pos->{index} != 0 )
    {
        $work_pos->{index} = 0;
        my( undef, $temp ) = $self->{rule_set}->parse( $work, $work_pos, 10, $mask, $rc );
        my $digit = _get_long( $temp );
        if( $lenient && $work_pos->{index} == 0 )
        {
            $fmt //= $self->{rule_set}->get_owner->_default_number_format;
            if( $fmt )
            {
                $temp = $fmt->parse( $work, $work_pos );
                $digit = _get_long( $temp );
            }
        }
        if( $work_pos->{index} != 0 )
        {
            $value = $value * 10 + $digit;
            $digits .= ( $digit >= 0 && $digit <= 9 ) ? $digit : '';
            $total++;
            $parse_pos->{index} += $work_pos->{index};
            substr( $work, 0, $work_pos->{index}, '' );
            while( length( $work ) && substr( $work, 0, 1 ) eq ' ' )
            {
                substr( $work, 0, 1, '' );
                $parse_pos->{index}++;
            }
        }
    }
    # DecimalQuantity::appendDigit() accumulates the digits as an integer, then
    # adjustMagnitude() shifts the value by the number of digits read.
    my $result = 0;
    if( $total )
    {
        $result = length( $digits ) == $total ? ( $digits . "e-" . $total ) + 0 : $value / ( 10 ** $total );
    }
    return( 1, $self->compose_rule_value( $result, $base_value ) );
}

sub modulus_do_parse
{
    my( $self, $text, $pp, $base_value, $upper_bound, $lenient, $mask, $rc ) = @_;
    return( Locale::Unicode::RBNF::Substitution::do_parse( $self, $text, $pp, $base_value, $upper_bound, $lenient, $mask, $rc ) ) if( !$self->{rule_to_use} );
    # A >>> substitution uses the specific rule's doParse() and does some of the work of
    # NFRuleSet::parse() itself.
    my( undef, $result ) = $self->{rule_to_use}->do_parse( $text, $pp, 0, $upper_bound, $mask, $rc + 1 );
    $result = $self->compose_rule_value( $result, $base_value ) if( $pp->{index} != 0 );
    return( 1, $result );
}

sub numerator_do_parse
{
    my( $self, $text, $parse_pos, $base_value, $upper_bound, $lenient, $mask, $rc ) = @_;
    # Lenient parsing is turned off here: it seriously messes up the algorithm.
    my $zero_count = 0;
    my $work = $text;
    if( $self->{with_zeros} && $self->{rule_set} )
    {
        my $work_pos = { index => 1, error => -1 };
        while( length( $work ) && $work_pos->{index} != 0 )
        {
            $work_pos->{index} = 0;
            # Parse zero, or nothing at all.
            $self->{rule_set}->parse( $work, $work_pos, 1, $mask, $rc );
            last if( $work_pos->{index} == 0 );
            ++$zero_count;
            $parse_pos->{index} += $work_pos->{index};
            substr( $work, 0, $work_pos->{index}, '' );
            while( length( $work ) && substr( $work, 0, 1 ) eq ' ' )
            {
                substr( $work, 0, 1, '' );
                $parse_pos->{index}++;
            }
        }
        $work = substr( $text, $parse_pos->{index} > length( $text ) ? length( $text ) : $parse_pos->{index} );
        $parse_pos->{index} = 0;
    }
    my( undef, $result ) = Locale::Unicode::RBNF::Substitution::do_parse( $self, $work, $parse_pos, ( $self->{with_zeros} ? 1 : $base_value ), $upper_bound, 0, $mask, $rc );
    if( $self->{with_zeros} )
    {
        # Compute the effective denominator and prescale the value down.
        my $n = _get_long( $result );
        my $d = 1;
        while( $d <= $n )
        {
            return(0) if( $d > idiv( $Locale::Unicode::RBNF::Util::INT64_MAX, 10 ) );
            $d *= 10;
        }
        while( $zero_count > 0 )
        {
            return(0) if( $d > idiv( $Locale::Unicode::RBNF::Util::INT64_MAX, 10 ) );
            $d *= 10;
            --$zero_count;
        }
        $result = $n / $d;
    }
    return( 1, $result );
}

# PluralFormat::parseType(): finds the longest sub-message occurring in $source at or
# after $starting_at. Returns ($begin, $end), or (-1, -1) if none is found.
sub plural_format_parse_type
{
    my( $self, $source, $rule, $starting_at ) = @_;
    return( -1, -1 ) if( !@{$self->{variants}} );
    $starting_at = 0 if( !defined( $starting_at ) || $starting_at < 0 );
    my $matched_index = -1;
    my $matched_word = '';
    foreach my $v ( @{$self->{variants}} )
    {
        # ICU walks the message parts as (selector, start, limit) triplets, which does
        # not line up for explicit values such as "=1", so those are never matched.
        next if( defined( $v->{explicit} ) );
        my $arg = $v->{raw};
        my $curr = -1;
        # UnicodeString::indexOf() never finds an empty string.
        if( length( $arg ) )
        {
            $curr = $starting_at > length( $source ) ? -1 : index( $source, $arg, $starting_at );
            ( $curr ) = $rule->_find_text_lenient( $source, $arg, $starting_at ) if( $curr < 0 && $rule );
        }
        if( $curr >= 0 && $curr >= $matched_index && length( $arg ) > length( $matched_word ) )
        {
            $matched_index = $curr;
            $matched_word = $arg;
        }
    }
    return( $matched_index, $matched_index + length( $matched_word ) ) if( $matched_index >= 0 );
    return( -1, -1 );
}

# RuleBasedNumberFormat::parse(): every public and parseable rule set is tried, and
# the one matching the most characters wins. Returns ($result, $index, $error_index), as
# the C engine does; Locale::Unicode::RBNF->parse() derives its own return values from
# them.
sub rbnf_parse_text
{
    my( $self, $working ) = @_;
    # Memoised lenient searches are only valid for the duration of one parse.
    $self->{lenient_memo} = {};
    my $high_pp = { index => 0, error => -1 };
    my $high_result = 0;
    foreach my $rs ( @{$self->{rule_sets}} )
    {
        next if( !$rs->is_public || !$rs->is_parseable );
        my $working_pp = { index => 0, error => -1 };
        my( undef, $result ) = $rs->parse( $working, $working_pp, $Locale::Unicode::RBNF::K_MAX_DOUBLE, 0, 0 );
        if( $working_pp->{index} > $high_pp->{index} )
        {
            $high_pp = $working_pp;
            $high_result = $result;
            last if( $high_pp->{index} == length( $working ) );
        }
    }
    $self->{lenient_memo} = undef;
    return( $high_result, $high_pp->{index}, $high_pp->{error} );
}

sub rule_all_ignorable { return( !length( $_[1] ) ); }

# NFRule::doParse(). $pp is a parse position {index, error}. Returns ($success, $value).
sub rule_do_parse
{
    my( $self, $text, $parse_pos, $is_fraction_rule, $upper_bound, $mask, $rc ) = @_;
    my $pp = { index => 0, error => -1 };
    my $work = $text;
    my $rule_text = $self->{rule_text};
    my $sub1_pos = $self->{sub1} ? $self->{sub1}->{pos} : length( $rule_text );
    my $sub2_pos = $self->{sub2} ? $self->{sub2}->{pos} : length( $rule_text );

    # Check whether the text before the first substitution matches the beginning of the
    # text being parsed. If it does, strip it off; otherwise, dump out with a mismatch.
    my $prefix = substr( $rule_text, 0, $sub1_pos );
    $self->_strip_prefix( \$work, $prefix, $pp );
    my $prefix_length = length( $text ) - length( $work );
    if( $pp->{index} == 0 && $sub1_pos != 0 )
    {
        $parse_pos->{error} = $pp->{error};
        return( 1, 0 );
    }
    if( $self->{base_value} == Locale::Unicode::RBNF::Rule::INFINITY_RULE() )
    {
        $parse_pos->{index} = $pp->{index};
        return( 1, 9**9**9 );
    }
    if( $self->{base_value} == Locale::Unicode::RBNF::Rule::NAN_RULE() )
    {
        $parse_pos->{index} = $pp->{index};
        return( 1, 9**9**9 - 9**9**9 );
    }

    # matchToDelimiter() is called twice: first to match the text between the
    # substitutions against the first substitution, then to match the text after the
    # second substitution.
    my $hwm = 0;
    my $result = 0;
    my $start = 0;
    my $temp_base = $self->{base_value} <= 0 ? 0 : $self->{base_value};
    do
    {
        $pp->{index} = 0;
        my $partial = $self->_match_to_delimiter( $work, $start, $temp_base, substr( $rule_text, $sub1_pos, $sub2_pos - $sub1_pos ), $pp, $self->{sub1}, $mask, $rc, $upper_bound );
        if( $pp->{index} != 0 || !$self->{sub1} )
        {
            $start = $pp->{index};
            my $work2 = substr( $work, $pp->{index} );
            my $pp2 = { index => 0, error => -1 };
            $partial = $self->_match_to_delimiter( $work2, 0, $partial, substr( $rule_text, $sub2_pos ), $pp2, $self->{sub2}, $mask, $rc, $upper_bound );
            if( $pp2->{index} != 0 || !$self->{sub2} )
            {
                if( $prefix_length + $pp->{index} + $pp2->{index} > $hwm )
                {
                    $hwm = $prefix_length + $pp->{index} + $pp2->{index};
                    $result = $partial;
                }
            }
            else
            {
                my $i_temp = $pp2->{error} + $sub1_pos + $pp->{index};
                $parse_pos->{error} = $i_temp if( $i_temp > $parse_pos->{error} );
            }
        }
        else
        {
            my $i_temp = $sub1_pos + $pp->{error};
            $parse_pos->{error} = $i_temp if( $i_temp > $parse_pos->{error} );
        }
    } while( $sub1_pos != $sub2_pos &&
        $pp->{index} > 0 &&
        $pp->{index} < length( $work ) &&
        $pp->{index} != $start );

    $parse_pos->{index} = $hwm;
    $parse_pos->{error} = 0 if( $hwm > 0 );
    # A rule in a fraction rule set without any substitution has a numerator of 1,
    # so the result is the reciprocal of its base value.
    if( $is_fraction_rule && $hwm > 0 && !$self->{sub1} )
    {
        # Division by zero yields infinity in C++, whereas Perl would die.
        $result = $result ? ( 1 / $result ) : 9**9**9;
    }
    return( 1, $result );
}

# Returns ( $position, $length ) of the key in the string, or (-1, 0)
sub rule_find_text
{
    my( $self, $str, $key, $starting_at ) = @_;
    if( my $pf = $self->{plural_format} )
    {
        my( $begin, $end ) = $pf->parse_type( $str, $self, $starting_at );
        if( $begin >= 0 )
        {
            my $text = $self->{rule_text};
            my $plural_start = index( $text, '$(' );
            my $plural_suffix = index( $text, ')$', $plural_start ) + 2;
            my $match_len = $end - $begin;
            my $prefix = substr( $text, 0, $plural_start );
            my $suffix = substr( $text, $plural_suffix );
            if( Locale::Unicode::RBNF::Rule::_pinned( $str, $begin - length( $prefix ), length( $prefix ) ) eq $prefix &&
                Locale::Unicode::RBNF::Rule::_pinned( $str, $begin + $match_len, length( $suffix ) ) eq $suffix )
            {
                return( $begin - length( $prefix ), $match_len + length( $prefix ) + length( $suffix ) );
            }
        }
        return( -1, 0 );
    }
    my $pos = $starting_at > length( $str ) ? -1 : index( $str, $key, $starting_at );
    return( $pos, length( $key ) ) if( $pos >= 0 || !$self->{formatter}->{lenient} );
    return( $self->_find_text_lenient( $str, $key, $starting_at ) );
}

# NFRule::findTextLenient(): tries prefixLength() at each successive position. The
# position is passed as an offset rather than as a substring, to avoid copying the text
# at every step.
sub rule_find_text_lenient
{
    my( $self, $str, $key, $starting_at ) = @_;
    # The result only depends on the arguments and on the formatter settings, which do
    # not change during a parse, and the parse recursion asks the same question many
    # times. The formatter empties this cache at the start of every parse.
    my $memo = $self->{formatter} ? ( $self->{formatter}->{lenient_memo} //= {} ) : {};
    my $memo_key = join( "\0", $starting_at, $key, $str );
    return( @{$memo->{ $memo_key }} ) if( exists( $memo->{ $memo_key } ) );
    my @result = $self->_find_text_lenient_uncached( $str, $key, $starting_at );
    $memo->{ $memo_key } = \@result;
    return( @result );
}

sub rule_find_text_lenient_uncached
{
    my( $self, $str, $key, $starting_at ) = @_;
    my $len = length( $str );
    my $turkic = ( $self->{formatter} && $self->{formatter}->{case_fold_turkic} ) ? 1 : 0;
    my $pinfo = length( $key ) ? ( $PREFIX_CACHE->{ $turkic }->{ $key } //= _prefix_info( $key, $turkic ) ) : undef;
    my $first = $pinfo ? $pinfo->[4] : undef;
    my $lenient = ( $self->{formatter} && $self->{formatter}->{lenient} ) ? 1 : 0;
    for( my $p = $starting_at; $p < $len; ++$p )
    {
        # The quick rejection of _prefix_length_at(), done here to spare the call: it only
        # applies when the key does not start with the text itself.
        if( $lenient && defined( $first ) && !$pinfo->[3] && substr( $str, $p, length( $key ) ) ne $key )
        {
            my $i = $p;
            ++$i while( $i < $len && Locale::Unicode::RBNF::Rule::_is_lenient_separator( substr( $str, $i, 1 ) ) );
            last if( $i >= $len );
            my $c = substr( $str, $i, 1 );
            next if( ord( $c ) < 0x80 && ( $i + 1 >= $len || ord( substr( $str, $i + 1, 1 ) ) < 0x80 ) && Locale::Unicode::RBNF::Rule::_fold_case( $c, $turkic ) ne $first );
        }
        my $key_len = $self->_prefix_length_at( $str, $p, $key );
        return( $p, $key_len ) if( $key_len != 0 );
    }
    return( -1, 0 );
}

sub rule_match_to_delimiter
{
    my( $self, $text, $start_pos, $base_value, $delimiter, $pp, $sub, $mask, $rc, $upper_bound ) = @_;
    my $lenient = $self->{formatter}->{lenient} ? 1 : 0;
    if( !$self->_all_ignorable( $delimiter ) )
    {
        # Search the text for the delimiter, then use the substitution to match what precedes it.
        my $temp_pp = { index => 0, error => -1 };
        my $curr_pos = $start_pos;
        my $best_result = 0;
        my $best_set = 0;
        while(1)
        {
            $temp_pp->{index} = 0;
            my( $d_pos, $d_len ) = $self->_find_text( $text, $delimiter, $curr_pos );
            last if( $d_pos < 0 );
            my $sub_text = substr( $text, 0, $d_pos );
            if( length( $sub_text ) )
            {
                my( $success, $result ) = $sub->do_parse( $sub_text, $temp_pp, $base_value, $upper_bound, $lenient, $mask, $rc );
                if( $success && $temp_pp->{index} == $d_pos )
                {
                    $pp->{index} = $d_pos + $d_len;
                    $best_result = $result;
                    $best_set = 1;
                }
                else
                {
                    # We matched the delimiter once already and did not find a better match.
                    return( $best_result ) if( $best_set );
                    $pp->{error} = $temp_pp->{error} > 0 ? $temp_pp->{error} : $temp_pp->{index};
                }
            }
            # ICU would loop forever on a zero-length match; we always move forward.
            $curr_pos = $d_pos + ( $d_len > 0 ? $d_len : 1 );
            $temp_pp->{index} = 0;
        }
        return( $best_result ) if( $best_set );
        $pp->{index} = 0;
        return(0);
    }
    elsif( !$sub )
    {
        return( $base_value );
    }
    else
    {
        # The delimiter is empty, so we match as much of the text as possible against the
        # substitution.
        my $temp_pp = { index => 0, error => -1 };
        my( $success, $result ) = $sub->do_parse( $text, $temp_pp, $base_value, $upper_bound, $lenient, $mask, $rc );
        if( $success && $temp_pp->{index} != 0 )
        {
            $pp->{index} = $temp_pp->{index};
            return( $result );
        }
        $pp->{error} = $temp_pp->{error};
        return(0);
    }
}

# NFRule::prefixLength(): returns how many characters of $str match $prefix, or 0
sub rule_prefix_length { return( $_[0]->_prefix_length_at( $_[1], 0, $_[2] ) ); }

# The same, for the text of $str starting at $offset.
sub rule_prefix_length_at
{
    my( $self, $str, $offset, $prefix ) = @_;
    my $prefix_len = length( $prefix );
    return(0) if( !$prefix_len );
    return( $prefix_len ) if( substr( $str, $offset, $prefix_len ) eq $prefix );
    my $f = $self->{formatter};
    return(0) if( !$f || !$f->{lenient} );

    # In lenient mode, both strings are walked simultaneously: separators are skipped
    # in both, and the rest is compared with simple case folding, after NFC normalisation
    # applied segment by segment on $str.
    my $turkic = $f->{case_fold_turkic} ? 1 : 0;
    my $pinfo = ( $PREFIX_CACHE->{ $turkic }->{ $prefix } //= _prefix_info( $prefix, $turkic ) );
    my( $nfc_chars, $folded, $is_sep, $prefix_all_sep, $first_folded ) = @$pinfo;
    my $nfc_prefix_len = scalar( @$nfc_chars );
    my $str_len = length( $str );

    # Quick rejection, giving the same result as the full walk below: once leading
    # separators are skipped, an ASCII character followed by an ASCII character, or by
    # nothing, forms an NFC segment on its own, so it must fold to the first
    # non-separator character of the prefix.
    if( !$prefix_all_sep )
    {
        my $i = $offset;
        ++$i while( $i < $str_len && Locale::Unicode::RBNF::Rule::_is_lenient_separator( substr( $str, $i, 1 ) ) );
        return(0) if( $i >= $str_len );
        my $c = substr( $str, $i, 1 );
        if( ord( $c ) < 0x80 && ( $i + 1 >= $str_len || ord( substr( $str, $i + 1, 1 ) ) < 0x80 ) )
        {
            return(0) if( Locale::Unicode::RBNF::Rule::_fold_case( $c, $turkic ) ne $first_folded );
        }
    }
    my $str_idx = $offset;
    my $prefix_idx = 0;
    my $matched = 1;
    my @str_nfc;
    my $str_nfc_idx = 0;
    while( $prefix_idx < $nfc_prefix_len )
    {
        # Separators in $str are only skipped when the NFC buffer is exhausted, since
        # they are NFC-inert and always appear at segment boundaries.
        my $str_sep_count = 0;
        while( $str_nfc_idx >= scalar( @str_nfc ) && $str_idx < $str_len && Locale::Unicode::RBNF::Rule::_is_lenient_separator( substr( $str, $str_idx, 1 ) ) )
        {
            ++$str_idx;
            ++$str_sep_count;
        }
        ++$prefix_idx while( $prefix_idx < $nfc_prefix_len && $is_sep->[ $prefix_idx ] );
        if( $prefix_all_sep && $prefix_idx >= $nfc_prefix_len && $str_sep_count == 0 )
        {
            $matched = 0;
            last;
        }
        last if( $prefix_idx >= $nfc_prefix_len );
        if( $str_nfc_idx >= scalar( @str_nfc ) )
        {
            if( $str_idx >= $str_len )
            {
                $matched = 0;
                last;
            }
            # Read the next normalisation segment, up to the next NFC boundary.
            my $seg_start = $str_idx++;
            ++$str_idx while( $str_idx < $str_len && !Locale::Unicode::RBNF::Rule::_has_nfc_boundary_before( substr( $str, $str_idx, 1 ) ) );
            my $seg = substr( $str, $seg_start, $str_idx - $seg_start );
            @str_nfc = split( //, ( $seg =~ /[^\x00-\x7F]/ ? Unicode::Normalize::NFC( $seg ) : $seg ) );
            $str_nfc_idx = 0;
        }
        if( Locale::Unicode::RBNF::Rule::_fold_case( $str_nfc[ $str_nfc_idx++ ], $turkic ) ne $folded->[ $prefix_idx ] )
        {
            $matched = 0;
            last;
        }
        ++$prefix_idx;
    }
    return( $str_idx - $offset ) if( $matched );
    # ICU then falls back on a collator tailored with the %%lenient-parse rules, when
    # the rule description provides some. Collation tailoring is not available here, so
    # there is no further match. The CLDR data no longer ships any %%lenient-parse rule
    # set.
    return(0);
}

# NFRuleSet::parse(): matches the text against each rule, and keeps the result of the rule
# that matched the most characters. Returns ( $success, $value ) and updates $pos.
sub rule_set_parse
{
    my( $self, $text, $pos, $upper_bound, $mask, $rc ) = @_;
    my $result = 0;
    return( 0, 0 ) if( $rc >= $Locale::Unicode::RBNF::RuleSet::RECURSION_LIMIT );
    return( 0, 0 ) if( !length( $text ) );
    my $hwm = { index => 0, error => -1 };
    my $working = { %$pos };
    my $nnr = $self->{non_numerical_rules};
    # Try each of the negative, fraction, infinity and NaN rules.
    for( my $i = 0; $i < Locale::Unicode::RBNF::RuleSet::NON_NUMERICAL_RULE_LENGTH(); $i++ )
    {
        if( $nnr->[$i] && ( ( $mask >> $i ) & 1 ) == 0 )
        {
            # Mark this rule as executed so that we do not try to execute it again.
            $mask |= ( 1 << $i );
            my( $success, $temp ) = $nnr->[$i]->do_parse( $text, $working, 0, $upper_bound, $mask, $rc + 1 );
            if( $success && $working->{index} > $hwm->{index} )
            {
                $result = $temp;
                $hwm = { %$working };
            }
            $working = { %$pos };
        }
    }
    # Then the regular rules, starting at the end of the list so that the most significant
    # rule is tried first. Rules whose base value is not below the upper bound are skipped.
    my $ub = from_double( $upper_bound );
    my $rules = $self->{rules};
    for( my $i = scalar( @$rules ); --$i >= 0 && $hwm->{index} < length( $text ); )
    {
        next if( !$self->{is_fraction} && $rules->[$i]->{base_value} >= $ub );
        my( $success, $temp ) = $rules->[$i]->do_parse( $text, $working, $self->{is_fraction}, $upper_bound, $mask, $rc + 1 );
        if( $success && $working->{index} > $hwm->{index} )
        {
            $result = $temp;
            $hwm = { %$working };
        }
        $working = { %$pos };
    }
    # Point the caller's parse position at the first character we did not use.
    %$pos = %$hwm;
    return( 1, $result );
}

sub rule_strip_prefix
{
    my( $self, $text_ref, $prefix, $pp ) = @_;
    return if( !length( $prefix ) );
    my $pfl = $self->_prefix_length( $$text_ref, $prefix );
    if( $pfl != 0 )
    {
        $pp->{index} += $pfl;
        substr( $$text_ref, 0, $pfl, '' );
    }
    return;
}

# NFSubstitution::doParse(): parses with the rule set or the DecimalFormat, then
# composes the partial result with the value passed in. Returns ($success, $value).
sub substitution_do_parse
{
    my( $self, $text, $pp, $base_value, $upper_bound, $lenient, $mask, $rc ) = @_;
    $upper_bound = $self->calc_upper_bound( $upper_bound );
    my $result = 0;
    if( my $rs = $self->{rule_set} )
    {
        ( undef, $result ) = $rs->parse( $text, $pp, $upper_bound, $mask, $rc );
        if( $lenient && !$rs->is_fraction_rule_set && $pp->{index} == 0 )
        {
            # ICU uses NumberFormat::createInstance() for the default locale here; we
            # use the decimal format of the formatter's own locale.
            my $fmt = $rs->get_owner->_default_number_format;
            $result = $fmt->parse( $text, $pp ) if( $fmt );
        }
    }
    elsif( my $nf = $self->{number_format} )
    {
        $result = $nf->parse( $text, $pp );
    }
    if( $pp->{index} != 0 )
    {
        return( 1, $self->compose_rule_value( $result, $base_value ) );
    }
    return( 0, 0 );
}

# Formattable::getLong(): truncates a double, and clamps it to the int32 range.
sub _get_long
{
    my $v = shift( @_ );
    return(0) if( is_nan( $v ) );
    return( 2147483647 ) if( $v > 2147483647 );
    return( -2147483648 ) if( $v < -2147483648 );
    return( int( $v ) );
}

# This provides the NFC characters of a prefix, their case folding, whether each is a
# separator, and whether they all are.
# Prefixes come from the rule texts, so they are computed once.
sub _prefix_info
{
    my( $prefix, $turkic ) = @_;
    my @chars = split( //, Unicode::Normalize::NFC( $prefix ) );
    my @folded = map( Locale::Unicode::RBNF::Rule::_fold_case( $_, $turkic ), @chars );
    my @sep = map( Locale::Unicode::RBNF::Rule::_is_lenient_separator( $_ ), @chars );
    my $all_sep = ( grep( !$_, @sep ) ) ? 0 : 1;
    my( $first ) = grep( !$sep[ $_ ], 0..$#chars );
    return( [ \@chars, \@folded, \@sep, $all_sep, ( defined( $first ) ? $folded[ $first ] : undef ) ] );
}

# Inject the pure-Perl parsing methods into their classes.
# The methods of the parsing code path are installed in the classes they belong to, and
# _parse_text() in Locale::Unicode::RBNF, unless the C engine provides it.
{
    no warnings qw( once redefine );
    *Locale::Unicode::RBNF::DecimalFormat::parse = \&decimal_format_parse;
    *Locale::Unicode::RBNF::PluralFormat::parse_type = \&plural_format_parse_type;
    *Locale::Unicode::RBNF::Rule::do_parse = \&rule_do_parse;
    *Locale::Unicode::RBNF::Rule::_all_ignorable = \&rule_all_ignorable;
    *Locale::Unicode::RBNF::Rule::_find_text = \&rule_find_text;
    *Locale::Unicode::RBNF::Rule::_find_text_lenient = \&rule_find_text_lenient;
    *Locale::Unicode::RBNF::Rule::_find_text_lenient_uncached = \&rule_find_text_lenient_uncached;
    *Locale::Unicode::RBNF::Rule::_match_to_delimiter = \&rule_match_to_delimiter;
    *Locale::Unicode::RBNF::Rule::_prefix_length = \&rule_prefix_length;
    *Locale::Unicode::RBNF::Rule::_prefix_length_at = \&rule_prefix_length_at;
    *Locale::Unicode::RBNF::Rule::_strip_prefix = \&rule_strip_prefix;
    *Locale::Unicode::RBNF::RuleSet::parse = \&rule_set_parse;
    *Locale::Unicode::RBNF::Substitution::do_parse = \&substitution_do_parse;
    *Locale::Unicode::RBNF::Substitution::Modulus::do_parse = \&modulus_do_parse;
    *Locale::Unicode::RBNF::Substitution::FractionalPart::do_parse = \&fractional_part_do_parse;
    *Locale::Unicode::RBNF::Substitution::Numerator::do_parse = \&numerator_do_parse;
    *Locale::Unicode::RBNF::_parse_text = \&rbnf_parse_text if( $Locale::Unicode::RBNF::IsPurePerl || !defined( &Locale::Unicode::RBNF::_parse_text ) );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Locale::Unicode::RBNF::PP - Pure-Perl fallback for the Locale::Unicode::RBNF XS layer

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module is loaded automatically by L<Locale::Unicode::RBNF> when the XS shared object cannot be loaded, such as when the distribution was installed without a C compiler, or when the environment variable C<PERL_LOCALE_UNICODE_RBNF_PP> is set to a true value.

It holds the pure Perl implementation of the parsing code path, a port of ICU4C 79.1, which the XS layer otherwise provides in C. All functions defined here are injected directly into the namespace of the class they belong to, so that callers see them transparently as methods.

Loading it while the XS layer is in use only installs those methods, and does not replace the C parsing engine; the test suite relies on this to compare both engines.

You should not normally load or call this module directly.

=head1 FUNCTIONS

Each function is a port of an ICU method, injected into a class as shown below. They are documented here as they are defined, with C<$self> being an object of that class; see L<Locale::Unicode::RBNF::Rule/CONVENTIONS> for the arguments they share.

=head2 decimal_format_parse

Installed as L<Locale::Unicode::RBNF::DecimalFormat/parse>.

    my $value = $decimal_format->parse( $text, $pp );

Parses a number at C<< $pp->{index} >>. On success, the index is moved past the number; otherwise, it is left unchanged and the error index is set. Returns the value.

=head2 fractional_part_do_parse

Installed as C<do_parse> in L<Locale::Unicode::RBNF::Substitution/Locale::Unicode::RBNF::Substitution::FractionalPart>.

    my( $success, $value ) = $sub->do_parse( $text, $pp, $base_value, $upper_bound, $lenient, $mask, $rc );

This is ICU C<FractionalPartSubstitution::doParse()>: in "by digits" mode, the text is parsed one digit at a time with the owning rule set, using an upper bound of 10, until the text no longer matches.

=head2 modulus_do_parse

Installed as C<do_parse> in L<Locale::Unicode::RBNF::Substitution/Locale::Unicode::RBNF::Substitution::Modulus>.

    my( $success, $value ) = $sub->do_parse( $text, $pp, $base_value, $upper_bound, $lenient, $mask, $rc );

This is ICU C<ModulusSubstitution::doParse()>: a C<<< >>> >>> substitution uses the C<doParse()> of the preceding rule, and does some of the work of C<NFRuleSet::parse()> itself.

=head2 numerator_do_parse

Installed as C<do_parse> in L<Locale::Unicode::RBNF::Substitution/Locale::Unicode::RBNF::Substitution::Numerator>.

    my( $success, $value ) = $sub->do_parse( $text, $pp, $base_value, $upper_bound, $lenient, $mask, $rc );

This is ICU C<NumeratorSubstitution::doParse()>. Lenient parsing is turned off here, as ICU does, since it seriously disrupts the algorithm.

=head2 plural_format_parse_type

Installed as L<Locale::Unicode::RBNF::PluralFormat/parse_type>.

    my( $begin, $end ) = $plural_format->parse_type( $source, $rule, $starting_at );

This is ICU C<PluralFormat::parseType()>: it finds the longest sub-message occurring in C<$source> at or after C<$starting_at>, and returns its beginning and its end, or C<( -1, -1 )> if none is found.

=head2 rbnf_parse_text

Installed as C<_parse_text> in L<Locale::Unicode::RBNF> when the pure Perl engine is in use.

    my( $result, $index, $error_index ) = $formatter->_parse_text( $text );

This is ICU C<RuleBasedNumberFormat::parse()>: every public and parseable rule set is tried, and the one matching the most characters wins. It returns the value, the number of characters matched, and the error index, as the C engine does; L<Locale::Unicode::RBNF/parse> derives its own return values from them.

=head2 rule_all_ignorable

Installed as C<_all_ignorable> in L<Locale::Unicode::RBNF::Rule>.

    my $bool = $rule->_all_ignorable( $string );

This is ICU C<NFRule::allIgnorable()>: it returns true if the string is empty. Collation is not available, so no other string is ignorable.

=head2 rule_do_parse

Installed as L<Locale::Unicode::RBNF::Rule/do_parse>.

    my( $success, $value ) = $rule->do_parse( $text, $pp, $is_fraction_rule, $upper_bound, $mask, $rc );

This is ICU C<NFRule::doParse()>: it strips the text before the first substitution, matches the substitutions up to their delimiters, and returns whether something was matched, and the value parsed. C<< $pp->{index} >> is set to the number of characters matched.

=head2 rule_find_text

Installed as C<_find_text> in L<Locale::Unicode::RBNF::Rule>.

    my( $position, $length ) = $rule->_find_text( $string, $key, $starting_at );

This is ICU C<NFRule::findText()>: it returns the position and the length of the key in the string, at or after C<$starting_at>, or C<( -1, 0 )> if it is not found. If the rule text has a plural sub-message, the key is matched with L<Locale::Unicode::RBNF::PluralFormat/parse_type>, together with the rule text around the sub-message. Otherwise, the key is searched as is, then, if the formatter is lenient, with L</rule_find_text_lenient>.

=head2 rule_find_text_lenient

Installed as C<_find_text_lenient> in L<Locale::Unicode::RBNF::Rule>.

    my( $position, $length ) = $rule->_find_text_lenient( $string, $key, $starting_at );

This is ICU C<NFRule::findTextLenient()>: it tries L</rule_prefix_length_at> at each successive position. The result only depends on the arguments and on the formatter settings, which do not change during a parse, so it is memoised for the duration of a parse.

=head2 rule_find_text_lenient_uncached

Installed as C<_find_text_lenient_uncached> in L<Locale::Unicode::RBNF::Rule>.

The same as L</rule_find_text_lenient>, without the memoisation.

=head2 rule_match_to_delimiter

Installed as C<_match_to_delimiter> in L<Locale::Unicode::RBNF::Rule>.

    my $value = $rule->_match_to_delimiter( $text, $start_pos, $base_value, $delimiter, $pp, $sub, $mask, $rc, $upper_bound );

This is ICU C<NFRule::matchToDelimiter()>: it searches the text for the delimiter, and uses the substitution C<$sub> to match what precedes it. Without a delimiter, the substitution matches as much text as it can. It returns the value, and sets C<$pp>.

=head2 rule_prefix_length

Installed as C<_prefix_length> in L<Locale::Unicode::RBNF::Rule>.

    my $length = $rule->_prefix_length( $string, $prefix );

This is ICU C<NFRule::prefixLength()>: it returns how many characters at the start of the string match the prefix, or 0 if they do not. In lenient mode, the comparison is made after NFC normalisation and simple case folding, Turkic for Turkish and Azerbaijani, and ignores separators, as ICU 79 does.

=head2 rule_prefix_length_at

Installed as C<_prefix_length_at> in L<Locale::Unicode::RBNF::Rule>.

    my $length = $rule->_prefix_length_at( $string, $offset, $prefix );

The same as L</rule_prefix_length>, for the text of the string starting at C<$offset>, which avoids copying the text at every step.

=head2 rule_set_parse

Installed as L<Locale::Unicode::RBNF::RuleSet/parse>.

    my( $success, $value ) = $rule_set->parse( $text, $pp, $upper_bound, $mask, $rc );

This is ICU C<NFRuleSet::parse()>: it matches the text against each rule, and keeps the result of the rule that matched the most characters.

=head2 rule_strip_prefix

Installed as C<_strip_prefix> in L<Locale::Unicode::RBNF::Rule>.

    $rule->_strip_prefix( \$text, $prefix, $pp );

This is ICU C<NFRule::stripPrefix()>: if the text starts with the prefix, as matched by L</rule_prefix_length>, the prefix is removed from the text, and C<< $pp->{index} >> is advanced by its length.

=head2 substitution_do_parse

Installed as L<Locale::Unicode::RBNF::Substitution/do_parse>.

    my( $success, $value ) = $sub->do_parse( $text, $pp, $base_value, $upper_bound, $lenient, $mask, $rc );

This is ICU C<NFSubstitution::doParse()>: it parses with the rule set or the decimal format, then composes the partial result with the value passed in.

=head1 SEE ALSO

L<Locale::Unicode::RBNF>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

Portions are derived from ICU, Copyright (C) 2016 and later Unicode, Inc. and others, under the Unicode License (L<https://www.unicode.org/copyright.html>). Its text is in the F<LICENSE-UNICODE> file of this distribution.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
