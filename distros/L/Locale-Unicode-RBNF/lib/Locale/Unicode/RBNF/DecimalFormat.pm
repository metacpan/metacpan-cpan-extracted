##----------------------------------------------------------------------------
## Unicode Rule-Based Number Format - ~/lib/Locale/Unicode/RBNF/DecimalFormat.pm
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
# The subset of ICU DecimalFormat that rule-based number format substitutions need:
# patterns made of '#', '0', ',' and '.', with literal affixes, an optional negative
# sub-pattern, and percent or per mille. Rounding is half-even, as for ICU's
# DecimalFormat by default.
package Locale::Unicode::RBNF::DecimalFormat;
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
    use Unicode::UCD ();
    use Locale::Unicode::RBNF::Util qw( :all );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

my $DIGIT_VALUES = {};

sub new
{
    my( $this, $pattern, $symbols, $st ) = @_;
    my $self = bless( { pattern => $pattern, symbols => $symbols }, ( ref( $this ) || $this ) );
    $self->_apply_pattern( $pattern, $st );
    return( $self );
}

sub format
{
    my( $self, $n, $is_int ) = @_;
    my $sym = $self->{symbols};
    my $neg = ( !is_nan( $n ) && $n < 0 ) ? 1 : 0;
    my $pos = $self->{positive};
    my $negp = $self->{negative};
    my $body;
    if( is_nan( $n ) )
    {
        return( $pos->{prefix} . $sym->{nan} . $pos->{suffix} );
    }
    elsif( is_infinite( $n ) )
    {
        $body = $sym->{infinity};
    }
    else
    {
        my $d = dec_from_number( $n, $is_int );
        $d->{scale} += $self->{multiplier_exp} if( length( $d->{digits} ) );
        dec_round( $d, -$self->{max_frac}, 'half_even' );
        $body = $self->_format_digits( $d );
    }
    if( $neg )
    {
        return( $negp->{prefix} . $body . $negp->{suffix} ) if( $negp );
        return( $self->_localise_affix( '-' ) . $pos->{prefix} . $body . $pos->{suffix} );
    }
    return( $pos->{prefix} . $body . $pos->{suffix} );
}

sub set_symbols
{
    my( $self, $symbols ) = @_;
    $self->{symbols} = $symbols;
    my $st;
    $self->_apply_pattern( $self->{pattern}, \$st );
    return( $self );
}

sub to_pattern { return( $_[0]->{pattern} ); }

sub _apply_pattern
{
    my( $self, $pattern, $st ) = @_;
    my @subs = _split_unquoted( $pattern, ';' );
    my $positive = $self->_parse_subpattern( $subs[0], $st );
    return if( $$st );
    $self->{positive} = { prefix => $positive->{prefix}, suffix => $positive->{suffix} };
    $self->{negative} = undef;
    if( defined( $subs[1] ) && length( $subs[1] ) )
    {
        my $negative = $self->_parse_subpattern( $subs[1], $st );
        return if( $$st );
        $self->{negative} = { prefix => $negative->{prefix}, suffix => $negative->{suffix} };
    }
    $self->{$_} = $positive->{$_} for( qw( min_int min_frac max_frac grouping primary secondary decimal_always multiplier_exp ) );
    return;
}

sub _digit_value
{
    my $c = shift( @_ );
    return if( !defined( $c ) || !length( $c ) || $c !~ /^\p{Nd}$/ );
    return( $DIGIT_VALUES->{ $c } ) if( exists( $DIGIT_VALUES->{ $c } ) );
    my $info = Unicode::UCD::charinfo( ord( $c ) );
    return( $DIGIT_VALUES->{ $c } = ( $info && length( $info->{decimal} ) ) ? $info->{decimal} : undef );
}

sub _format_digits
{
    my( $self, $d ) = @_;
    my $sym = $self->{symbols};
    my $digits = $sym->{digits} || [0..9];
    my( $int, $frac ) = ( '', '' );
    if( length( $d->{digits} ) )
    {
        my $top = $d->{scale} + length( $d->{digits} ) - 1;
        for( my $m = $top; $m >= 0; $m-- )
        {
            $int .= dec_get_digit( $d, $m );
        }
        my $low = $d->{scale} < 0 ? $d->{scale} : 0;
        for( my $m = -1; $m >= $low; $m-- )
        {
            $frac .= dec_get_digit( $d, $m );
        }
    }
    $int = ( '0' x ( $self->{min_int} - length( $int ) ) ) . $int if( length( $int ) < $self->{min_int} );
    $frac .= '0' x ( $self->{min_frac} - length( $frac ) ) if( length( $frac ) < $self->{min_frac} );
    $int = '0' if( !length( $int ) && !length( $frac ) );
    my $out_int = join( '', map( $digits->[ $_ ], split( //, $int ) ) );
    if( $self->{grouping} && $self->{primary} > 0 && length( $int ) > $self->{primary} )
    {
        my @chars = split( //, $out_int );
        my @groups = ( join( '', splice( @chars, -$self->{primary} ) ) );
        my $size = $self->{secondary} > 0 ? $self->{secondary} : $self->{primary};
        while( @chars )
        {
            unshift( @groups, join( '', splice( @chars, ( @chars > $size ? -$size : 0 ) ) ) );
        }
        $out_int = join( $sym->{group}, @groups );
    }
    my $out = $out_int;
    if( length( $frac ) )
    {
        $out .= $sym->{decimal} . join( '', map( $digits->[ $_ ], split( //, $frac ) ) );
    }
    elsif( $self->{decimal_always} )
    {
        $out .= $sym->{decimal};
    }
    return( $out );
}

# Literal affix text: quotes are removed and '-' and '%' are localised.
sub _localise_affix
{
    my( $self, $affix ) = @_;
    my $sym = $self->{symbols};
    my $out = '';
    my $in_quote = 0;
    for( my $i = 0; $i < length( $affix ); $i++ )
    {
        my $c = substr( $affix, $i, 1 );
        if( $c eq "'" )
        {
            if( substr( $affix, $i + 1, 1 ) eq "'" )
            {
                $out .= "'";
                $i++;
            }
            else
            {
                $in_quote = !$in_quote;
            }
            next;
        }
        if( !$in_quote )
        {
            if( $c eq '-' ) { $out .= $sym->{minus}; next; }
            if( $c eq '+' ) { $out .= $sym->{plus}; next; }
            if( $c eq '%' ) { $out .= $sym->{percent} // '%'; next; }
            if( $c eq "\x{2030}" ) { $out .= $sym->{per_mille} // "\x{2030}"; next; }
        }
        $out .= $c;
    }
    return( $out );
}

sub _parse_subpattern
{
    my( $self, $pattern, $st ) = @_;
    my $def = { prefix => '', suffix => '', min_int => 0, min_frac => 0, max_frac => 0, grouping => 0, primary => 0, secondary => 0, decimal_always => 0, multiplier_exp => 0 };
    # Locate the number part outside of quotes.
    my( $start, $end ) = ( -1, -1 );
    my $in_quote = 0;
    for( my $i = 0; $i < length( $pattern ); $i++ )
    {
        my $c = substr( $pattern, $i, 1 );
        # The number part is one contiguous run of pattern characters outside of quotes.
        if( $c eq "'" )
        {
            last if( $start >= 0 );
            $in_quote = !$in_quote;
            next;
        }
        next if( $in_quote );
        if( $c =~ /^[#0,.]$/ )
        {
            $start = $i if( $start < 0 );
            $end = $i;
        }
        elsif( $start >= 0 )
        {
            last;
        }
    }
    if( $start < 0 )
    {
        $$st = 'U_PATTERN_SYNTAX_ERROR: no number in pattern "' . $pattern . '"';
        return( $def );
    }
    my $number = substr( $pattern, $start, $end - $start + 1 );
    my $prefix = substr( $pattern, 0, $start );
    my $suffix = substr( $pattern, $end + 1 );
    if( $prefix =~ /[1-9\@]$/ || $suffix =~ /^[1-9\@E]/ )
    {
        $$st = 'U_UNSUPPORTED_ERROR: significant digits, exponents and rounding increments are not supported in "' . $pattern . '"';
        return( $def );
    }
    $def->{multiplier_exp} = 2 if( ( $prefix . $suffix ) =~ /%/ );
    $def->{multiplier_exp} = 3 if( ( $prefix . $suffix ) =~ /\x{2030}/ );
    $def->{prefix} = $self->_localise_affix( $prefix );
    $def->{suffix} = $self->_localise_affix( $suffix );
    my( $int_part, $frac_part ) = split( /\./, $number, 2 );
    if( index( $number, '.' ) >= 0 )
    {
        $frac_part //= '';
        if( $frac_part =~ /[,.]/ || $frac_part !~ /^0*#*$/ )
        {
            $$st = 'U_PATTERN_SYNTAX_ERROR: malformed fraction in pattern "' . $pattern . '"';
            return( $def );
        }
        $def->{min_frac} = ( $frac_part =~ tr/0// );
        $def->{max_frac} = length( $frac_part );
        $def->{decimal_always} = 1 if( !length( $frac_part ) );
    }
    $int_part //= '';
    if( $int_part !~ /^[#,]*[0,]*$/ )
    {
        $$st = 'U_PATTERN_SYNTAX_ERROR: malformed integer part in pattern "' . $pattern . '"';
        return( $def );
    }
    $def->{min_int} = ( $int_part =~ tr/0// );
    if( index( $int_part, ',' ) >= 0 )
    {
        my @groups = split( /,/, $int_part, -1 );
        $def->{grouping} = 1;
        $def->{primary} = length( $groups[-1] );
        $def->{secondary} = @groups > 2 ? length( $groups[-2] ) : 0;
    }
    return( $def );
}

sub _split_unquoted
{
    my( $s, $sep ) = @_;
    my @parts = ( '' );
    my $in_quote = 0;
    foreach my $c ( split( //, $s ) )
    {
        $in_quote = !$in_quote if( $c eq "'" );
        if( !$in_quote && $c eq $sep )
        {
            push( @parts, '' );
            next;
        }
        $parts[-1] .= $c;
    }
    return( @parts );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Locale::Unicode::RBNF::DecimalFormat - Decimal pattern formatting for Locale::Unicode::RBNF

=head1 SYNOPSIS

    use Locale::Unicode::RBNF::DecimalFormat;
    my $st;
    my $nf = Locale::Unicode::RBNF::DecimalFormat->new( '#,##0.##', $cldr->symbols( 'fr', 'latn' ), \$st );
    die( $st ) if( $st );
    say $nf->format( 1234.567 );
    # 1 234,57

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Internal module. It implements the subset of ICU C<DecimalFormat> that rule-based number formats use in their substitutions, such as C<#,##0>, C<#,##,##0>, C<0.0> or C<#,##0.#>.

Significant digits (C<@>), exponents (C<E>), rounding increments and currency symbols are not supported, and a pattern using them is rejected.

=head1 CONSTRUCTOR

=head2 new

    my $nf = Locale::Unicode::RBNF::DecimalFormat->new( $pattern, $symbols, \$st );

Takes a decimal pattern, an hash reference of decimal format symbols, as returned by L<Locale::Unicode::RBNF::CLDR/symbols>, and a scalar reference that receives an error status, and returns a new object.

The object is always returned. If the pattern cannot be parsed, or uses a feature that is not supported, the status is set to an error message, and the caller must check it.

=head1 METHODS

=head2 format

    my $string = $nf->format( $number, $is_int );

Formats the number according to the pattern and the symbols, and returns the resulting string. The fraction digits are rounded half-even to the maximum number of fraction digits of the pattern, and the digits are those of the symbols' numbering system.

If C<$is_int> is true, the number is taken as an integer, digit for digit, so that integers beyond 2^53 keep their precision; otherwise, the shortest decimal representation of the double that round-trips is used, as ICU C<DecimalQuantity> does. C<NaN> and infinity are formatted with the C<nan> and C<infinity> symbols.

=head2 parse

    my $pp = { index => 0, error => -1 };
    my $value = $nf->parse( $text, $pp );

Parses a number at the position C<< $pp->{index} >> of the text, honouring the affixes, the grouping and decimal separators and the digits of the symbols, and returns its value. On success, the index is moved past the number; otherwise, it is left unchanged and C<< $pp->{error} >> is set to the position of the error.

This method is provided by L<Locale::Unicode::RBNF::PP>, and used by the pure Perl parsing engine.

=head2 set_symbols

    $nf->set_symbols( $symbols );

Replaces the decimal format symbols, and applies the pattern again so that its affixes are localised with the new symbols. It returns the current object.

=head2 to_pattern

Returns the pattern given to L</new>.

=head1 SEE ALSO

L<Locale::Unicode::RBNF>, L<Locale::Unicode::RBNF::CLDR>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
