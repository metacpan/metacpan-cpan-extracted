##----------------------------------------------------------------------------
## Unicode Rule-Based Number Format - ~/lib/Locale/Unicode/RBNF/Util.pm
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
# Numeric helpers reproducing the int64, uint64 and double semantics that ICU4C relies on
# in nfrs.cpp, nfrule.cpp and nfsubs.cpp, plus a small decimal representation standing in
# for ICU's DecimalQuantity.
package Locale::Unicode::RBNF::Util;
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
    use vars qw( @EXPORT_OK %EXPORT_TAGS $VERSION $MAX_MANTISSA $INT64_MAX $INT64_MIN $UINT64_MOD );
    use Exporter qw( import );
    use Math::BigInt;
    use POSIX ();
    @EXPORT_OK = qw(
        dec_from_number dec_get_digit dec_is_zero dec_lower_display_magnitude dec_round
        dbl_to_i32 dec_to_number from_double idiv imod is_infinite is_nan is_pattern_ws lcm
        pow_u64 str_insert to_i32 to_i64
    );
    %EXPORT_TAGS = ( all => [@EXPORT_OK] );
    # uprv_maxMantissa() is pow(2.0, DBL_MANT_DIG + 1.0) - 1.0
    $MAX_MANTISSA = ( 2 ** 54 ) - 1;
    $INT64_MAX = 9223372036854775807;
    $INT64_MIN = -9223372036854775807 - 1;
    $UINT64_MOD = Math::BigInt->new( '18446744073709551616' );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

# static_cast<int32_t>() of a double. Out of range, this is undefined behaviour in C++: x86
# yields INT32_MIN, while aarch64 saturates, as does the (int) cast of Java in ICU4J. We follow
# the defined Java semantics: saturation, and 0 for NaN.
sub dbl_to_i32
{
    my $n = shift( @_ );
    return(0) if( is_nan( $n ) );
    return( 2147483647 ) if( $n >= 2147483647 );
    return( -2147483648 ) if( $n <= -2147483648 );
    return( int( $n ) );
}

# Builds the decimal representation { neg, digits, scale } where the value is digits x 10^scale.
# Integers are taken digit for digit; doubles use the shortest representation that round-trips,
# which is what DecimalQuantity::setToDouble() produces.
sub dec_from_number
{
    my( $n, $is_int ) = @_;
    my $d = { neg => 0, digits => '', scale => 0 };
    if( $is_int )
    {
        my $s = "$n";
        $d->{neg} = 1 if( $s =~ s/^-// );
        $s =~ s/^\+//;
        $s =~ s/^0+//;
        _dec_normalise( $d, $s, 0 );
        return( $d );
    }
    return( $d ) if( $n == 0 );
    my $abs = $n < 0 ? -$n : $n;
    $d->{neg} = 1 if( $n < 0 );
    my( $mant, $exp );
    for my $p ( 1..17 )
    {
        my $s = sprintf( '%.*e', $p - 1, $abs );
        if( $s + 0 == $abs || $p == 17 )
        {
            ( $mant, $exp ) = split( /e/i, $s );
            last;
        }
    }
    $mant =~ s/\.//;
    _dec_normalise( $d, $mant, $exp - ( length( $mant ) - 1 ) );
    return( $d );
}

# DecimalQuantity::getDigit(): the digit at the given power of ten, 0 outside the stored digits.
sub dec_get_digit
{
    my( $d, $mag ) = @_;
    my $idx = $mag - $d->{scale};
    my $len = length( $d->{digits} );
    return(0) if( $idx < 0 || $idx >= $len );
    return( substr( $d->{digits}, $len - 1 - $idx, 1 ) );
}

sub dec_is_zero { return( !length( $_[0]->{digits} ) ); }

# DecimalQuantity::getLowerDisplayMagnitude() for a quantity with no minimum fraction digits.
sub dec_lower_display_magnitude
{
    my $d = shift( @_ );
    return(0) if( !length( $d->{digits} ) );
    return( $d->{scale} < 0 ? $d->{scale} : 0 );
}

# DecimalQuantity::roundToMagnitude(). Returns false when the mode is 'unnecessary' and
# rounding would have changed the value (ICU sets U_FORMAT_INEXACT_ERROR in that case).
sub dec_round
{
    my( $d, $mag, $mode ) = @_;
    return(1) if( !length( $d->{digits} ) || $d->{scale} >= $mag );
    my $drop = $mag - $d->{scale};
    my $len = length( $d->{digits} );
    my( $kept, $dropped );
    if( $drop >= $len )
    {
        $kept = '';
        $dropped = ( '0' x ( $drop - $len ) ) . $d->{digits};
    }
    else
    {
        $kept = substr( $d->{digits}, 0, $len - $drop );
        $dropped = substr( $d->{digits}, $len - $drop );
    }
    # The stored digits never end with a zero, so the dropped part is always non-zero here.
    my $nonzero = $dropped =~ /[1-9]/ ? 1 : 0;
    my $first = substr( $dropped, 0, 1 );
    my $rest_nonzero = substr( $dropped, 1 ) =~ /[1-9]/ ? 1 : 0;
    my $cmp_half = $first > 5 ? 1 : $first < 5 ? -1 : $rest_nonzero ? 1 : 0;
    my $last_odd = length( $kept ) ? ( substr( $kept, -1 ) % 2 ) : 0;
    my $inc = 0;
    $mode //= 'half_even';
    if( $mode eq 'unnecessary' )
    {
        return(0) if( $nonzero );
    }
    elsif( $mode eq 'up' ) { $inc = $nonzero; }
    elsif( $mode eq 'down' ) { $inc = 0; }
    elsif( $mode eq 'ceiling' ) { $inc = ( $nonzero && !$d->{neg} ) ? 1 : 0; }
    elsif( $mode eq 'floor' ) { $inc = ( $nonzero && $d->{neg} ) ? 1 : 0; }
    elsif( $mode eq 'half_up' ) { $inc = $cmp_half >= 0 ? 1 : 0; }
    elsif( $mode eq 'half_down' ) { $inc = $cmp_half > 0 ? 1 : 0; }
    elsif( $mode eq 'half_odd' ) { $inc = ( $cmp_half > 0 || ( $cmp_half == 0 && !$last_odd ) ) ? 1 : 0; }
    elsif( $mode eq 'half_ceiling' ) { $inc = ( $cmp_half > 0 || ( $cmp_half == 0 && !$d->{neg} ) ) ? 1 : 0; }
    elsif( $mode eq 'half_floor' ) { $inc = ( $cmp_half > 0 || ( $cmp_half == 0 && $d->{neg} ) ) ? 1 : 0; }
    else { $inc = ( $cmp_half > 0 || ( $cmp_half == 0 && $last_odd ) ) ? 1 : 0; }
    $kept = '0' if( !length( $kept ) );
    $kept = _str_increment( $kept ) if( $inc );
    $kept =~ s/^0+//;
    _dec_normalise( $d, $kept, $mag );
    return(1);
}

sub dec_to_number
{
    my $d = shift( @_ );
    return(0) if( !length( $d->{digits} ) );
    return( ( $d->{neg} ? '-' : '' ) . $d->{digits} . 'e' . $d->{scale} ) + 0;
}

# util64_fromDouble(): clamps to +/- uprv_maxMantissa(), then truncates towards zero.
sub from_double
{
    my $d = shift( @_ );
    return(0) if( is_nan( $d ) );
    if( $d < -$MAX_MANTISSA ) { $d = -$MAX_MANTISSA; }
    elsif( $d > $MAX_MANTISSA ) { $d = $MAX_MANTISSA; }
    my $neg = $d < 0;
    $d = -$d if( $neg );
    my $r = int( POSIX::floor( $d ) );
    return( $neg ? -$r : $r );
}

# Integer division and remainder with C semantics (truncation towards zero).
sub idiv
{
    use integer;
    return( $_[0] / $_[1] );
}

sub imod
{
    use integer;
    return( $_[0] % $_[1] );
}

sub is_infinite { return( defined( $_[0] ) && !is_nan( $_[0] ) && ( $_[0] == 9**9**9 || $_[0] == -9**9**9 ) ); }

sub is_nan { return( defined( $_[0] ) && $_[0] != $_[0] ); }

# PatternProps::isWhiteSpace()
# The Pattern_White_Space set is immutable by Unicode policy, so it is spelled out here.
sub is_pattern_ws { return( defined( $_[0] ) && length( $_[0] ) && $_[0] =~ /\A[\t\n\x0B\f\r \x{85}\x{200E}\x{200F}\x{2028}\x{2029}]\z/ ); }

# util_lcm() in nfrs.cpp: binary gcd from Knuth, then x / gcd * y, all in int64 arithmetic.
sub lcm
{
    use integer;
    my( $x, $y ) = @_;
    my( $x1, $y1 ) = ( $x, $y );
    my $p2 = 0;
    while( ( $x1 & 1 ) == 0 && ( $y1 & 1 ) == 0 )
    {
        ++$p2;
        $x1 >>= 1;
        $y1 >>= 1;
    }
    my $t = ( $x1 & 1 ) == 1 ? -$y1 : $x1;
    while( $t != 0 )
    {
        $t = $t >> 1 while( ( $t & 1 ) == 0 );
        if( $t > 0 ) { $x1 = $t; }
        else { $y1 = -$t; }
        $t = $x1 - $y1;
    }
    my $gcd = $x1 << $p2;
    return(0) if( !$gcd );
    return( $x / $gcd * $y );
}

# util64_pow(): uint64 arithmetic, so the result wraps modulo 2^64 like the C++ code does.
# The returned value is the unsigned result; use to_i64() where ICU stores it in an int64_t.
sub pow_u64
{
    my( $base, $exponent ) = @_;
    return(0) if( !$base );
    my $r = 1;
    for( my $i = 0; $i < $exponent; $i++ )
    {
        # Beyond 2^53 a double can no longer represent every integer, so we switch to
        # Math::BigInt to obtain the exact wrapped value.
        if( $r > ( 9007199254740992 / $base ) )
        {
            my $big = Math::BigInt->new( $base )->bpow( $exponent )->bmod( $UINT64_MOD );
            return( unpack( 'Q', pack( 'Q', "$big" ) ) );
        }
        $r *= $base;
    }
    return( $r );
}

# UnicodeString::insert() pins the position within the string.
sub str_insert
{
    my( $ref, $pos, $text ) = @_;
    return if( !defined( $text ) || !length( $text ) );
    $pos = 0 if( $pos < 0 );
    $pos = length( $$ref ) if( $pos > length( $$ref ) );
    substr( $$ref, $pos, 0, $text );
    return;
}

# static_cast<int32_t>() of an integral value: two's complement truncation.
sub to_i32
{
    my $n = shift( @_ );
    $n = int( $n );
    return( $n ) if( $n >= -2147483648 && $n <= 2147483647 );
    return( unpack( 'l', pack( 'L', ( Math::BigInt->new( "$n" )->bmod( 4294967296 ) )->numify ) ) );
}

# Conversion of a uint64_t to int64_t (two's complement), as happens implicitly in ICU.
sub to_i64
{
    my $n = shift( @_ );
    return( $n ) if( $n <= $INT64_MAX );
    return( unpack( 'q', pack( 'Q', $n ) ) );
}

sub _dec_normalise
{
    my( $d, $digits, $scale ) = @_;
    $digits =~ s/^0+//;
    if( !length( $digits ) )
    {
        $d->{digits} = '';
        $d->{scale} = 0;
        $d->{neg} = 0;
        return( $d );
    }
    if( $digits =~ s/(0+)$// )
    {
        $scale += length( $1 );
    }
    $d->{digits} = $digits;
    $d->{scale} = $scale;
    return( $d );
}

sub _str_increment
{
    my $s = shift( @_ );
    my @d = split( //, $s );
    my $i = $#d;
    while( $i >= 0 )
    {
        if( $d[$i] == 9 )
        {
            $d[$i] = 0;
            $i--;
        }
        else
        {
            $d[$i]++;
            last;
        }
    }
    unshift( @d, 1 ) if( $i < 0 );
    return( join( '', @d ) );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Locale::Unicode::RBNF::Util - Numeric helpers for Locale::Unicode::RBNF

=head1 SYNOPSIS

    use Locale::Unicode::RBNF::Util qw( :all );
    my $n = to_i64( pow_u64( 10, 19 ) );
    my $q = idiv( -7, 2 );
    # -3

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Internal module. It reproduces the C<int64_t>, C<uint64_t> and C<double> behaviour that ICU4C's rule-based number format relies upon, so that results are identical to ICU, including its overflow behaviour.

=head1 EXPORTS

Nothing is exported by default. All the functions below can be imported individually, or all at once with the tag C<:all>.

=head1 VARIABLES

=over 4

=item * C<$MAX_MANTISSA>

2^54 - 1, the value of ICU C<uprv_maxMantissa()>.

=item * C<$INT64_MAX> and C<$INT64_MIN>

The limits of an C<int64_t>.

=item * C<$UINT64_MOD>

2^64, as a L<Math::BigInt> object.

=back

=head1 FUNCTIONS

=head2 dbl_to_i32

    my $i = dbl_to_i32( $double );

This is C<static_cast<int32_t>> of a double. Out of range, this is undefined behaviour in C++: x86 yields C<INT32_MIN>, while aarch64 saturates, as does the C<(int)> cast of Java in ICU4J. The defined Java semantics are used: the value is truncated towards zero, saturated to the C<int32_t> range, and C<NaN> yields 0.

=head2 dec_from_number

    my $dec = dec_from_number( $number, $is_int );

Returns the decimal representation of a number as an hash reference with the keys C<neg>, C<digits> and C<scale>, where the value is C<digits> times 10 to the power of C<scale>, and C<digits> neither starts nor ends with a zero. Zero has empty C<digits>.

If C<$is_int> is true, the number is taken digit for digit, so that integers beyond 2^53 keep their precision. Otherwise, the shortest representation of the double that round-trips is used, which is what ICU C<DecimalQuantity::setToDouble()> produces.

=head2 dec_get_digit

    my $digit = dec_get_digit( $dec, $magnitude );

This is ICU C<DecimalQuantity::getDigit()>: it returns the digit at the given power of ten, or 0 outside the digits stored.

=head2 dec_is_zero

    my $bool = dec_is_zero( $dec );

Returns true if the decimal representation is zero.

=head2 dec_lower_display_magnitude

    my $magnitude = dec_lower_display_magnitude( $dec );

This is ICU C<DecimalQuantity::getLowerDisplayMagnitude()> for a quantity with no minimum fraction digits: the power of ten of the last fraction digit, or 0 if there is none.

=head2 dec_round

    my $ok = dec_round( $dec, $magnitude, $mode );

This is ICU C<DecimalQuantity::roundToMagnitude()>: it rounds the decimal representation, in place, to the given power of ten, with one of the rounding modes C<ceiling>, C<floor>, C<down>, C<up>, C<half_even> (the default), C<half_down>, C<half_up>, C<half_odd>, C<half_ceiling>, C<half_floor> and C<unnecessary>.

It returns false when the mode is C<unnecessary> and rounding would have changed the value, in which case the value is left unchanged, and ICU sets C<U_FORMAT_INEXACT_ERROR>. It returns true otherwise.

=head2 dec_to_number

    my $number = dec_to_number( $dec );

Returns the decimal representation as a Perl number.

=head2 from_double

    my $int = from_double( $double );

This is ICU C<util64_fromDouble()>: the double is clamped to plus or minus C<uprv_maxMantissa()>, 2^54 - 1, then truncated towards zero. C<NaN> yields 0.

=head2 idiv

    my $q = idiv( $x, $y );

Returns the integer division of C<$x> by C<$y> with C semantics, that is truncated towards zero.

=head2 imod

    my $r = imod( $x, $y );

Returns the remainder of the integer division of C<$x> by C<$y> with C semantics, that is with the sign of C<$x>.

=head2 is_infinite

    my $bool = is_infinite( $number );

Returns true if the number is defined and is a positive or negative infinity.

=head2 is_nan

    my $bool = is_nan( $number );

Returns true if the number is defined and is C<NaN>.

=head2 is_pattern_ws

    my $bool = is_pattern_ws( $char );

This is ICU C<PatternProps::isWhiteSpace()>: it returns true if the character belongs to the C<Pattern_White_Space> set. That set is immutable by Unicode policy, so it is spelled out in the code.

=head2 lcm

    my $lcm = lcm( $x, $y );

This is C<util_lcm()> of ICU F<nfrs.cpp>: the least common multiple, computed with the binary gcd of Knuth, then C<x / gcd * y>, all in C<int64_t> arithmetic. It returns 0 if the gcd is 0.

=head2 pow_u64

    my $n = pow_u64( $base, $exponent );

This is ICU C<util64_pow()>: it raises the base to the power of the exponent in C<uint64_t> arithmetic, so that the result wraps modulo 2^64 as the C++ code does. Beyond 2^53, the exact wrapped value is computed with L<Math::BigInt>. The result is unsigned; use L</to_i64> where ICU stores it in an C<int64_t>.

=head2 str_insert

    str_insert( \$string, $pos, $text );

This is ICU C<UnicodeString::insert()>: it inserts the text into the string referenced, at the position given, pinned within the string.

=head2 to_i32

    my $i = to_i32( $integer );

This is C<static_cast<int32_t>> of an integral value: two's complement truncation.

=head2 to_i64

    my $i = to_i64( $unsigned );

Converts a C<uint64_t> value to an C<int64_t> (two's complement), as happens implicitly in ICU.

=head1 SEE ALSO

L<Locale::Unicode::RBNF>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
