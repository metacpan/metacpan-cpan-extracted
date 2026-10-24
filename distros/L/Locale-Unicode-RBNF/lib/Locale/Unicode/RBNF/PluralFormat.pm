##----------------------------------------------------------------------------
## Unicode Rule-Based Number Format - ~/lib/Locale/Unicode/RBNF/PluralFormat.pm
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
# The plural-only message patterns used inside $(cardinal,...)$ and $(ordinal,...)$,
# as ICU PluralFormat handles them for rule-based number formats (format() and parseType()).
package Locale::Unicode::RBNF::PluralFormat;
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
    use Locale::Unicode::RBNF::Util ();
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

# $rules is a Locale::Unicode::RBNF::PluralRules object and $number_format the decimal format
# used to replace '#' in a sub-message.
sub new
{
    my( $this, $rules, $pattern, $number_format, $st ) = @_;
    my $self = bless(
    {
        rules           => $rules,
        pattern         => $pattern,
        number_format   => $number_format,
        offset          => 0,
        variants        => [],
    }, ( ref( $this ) || $this ) );
    $self->_parse_pattern( $pattern, $st );
    return( $self );
}

sub format
{
    my( $self, $number, $st ) = @_;
    my $msg = $self->_find_sub_message( $number );
    return( '' ) if( !defined( $msg ) );
    return( $self->_expand( $msg, $number - $self->{offset} ) );
}

sub to_pattern { return( $_[0]->{pattern} ); }

# Replaces '#' with the formatted number, and resolves apostrophe quoting as MessageFormat
# does in its default ApostropheMode (DOUBLE_OPTIONAL).
sub _expand
{
    my( $self, $msg, $number ) = @_;
    my $out = '';
    my $len = length( $msg );
    my $depth = 0;
    for( my $i = 0; $i < $len; $i++ )
    {
        my $c = substr( $msg, $i, 1 );
        if( $c eq "'" )
        {
            my $next = $i + 1 < $len ? substr( $msg, $i + 1, 1 ) : '';
            if( $next eq "'" )
            {
                $out .= "'";
                $i++;
                next;
            }
            if( $next =~ /^[{}#|]$/ )
            {
                my $end = index( $msg, "'", $i + 1 );
                $end = $len if( $end < 0 );
                $out .= substr( $msg, $i + 1, $end - $i - 1 );
                $i = $end;
                next;
            }
        }
        elsif( $c eq '{' ) { $depth++; }
        elsif( $c eq '}' ) { $depth--; }
        elsif( $c eq '#' && $depth == 0 )
        {
            $out .= $self->{number_format} ? $self->{number_format}->format( $number, ( $number == int( $number ) ? 1 : 0 ) ) : $number;
            next;
        }
        $out .= $c;
    }
    return( $out );
}

# Explicit values take precedence, then the keyword selected by the plural rules, then "other".
sub _find_sub_message
{
    my( $self, $number ) = @_;
    my( $keyword_msg, $other_msg );
    my $keyword = $self->{rules} ? $self->{rules}->select( $number - $self->{offset} ) : 'other';
    foreach my $v ( @{$self->{variants}} )
    {
        if( defined( $v->{explicit} ) )
        {
            return( $v->{raw} ) if( $v->{explicit} == $number );
        }
        elsif( $v->{keyword} eq 'other' )
        {
            $other_msg //= $v->{raw};
        }
        elsif( $v->{keyword} eq $keyword )
        {
            $keyword_msg //= $v->{raw};
        }
    }
    return( $keyword_msg // $other_msg );
}

sub _parse_pattern
{
    my( $self, $pattern, $st ) = @_;
    my $len = length( $pattern );
    my $i = 0;
    my $skip_ws = sub
    {
        $i++ while( $i < $len && Locale::Unicode::RBNF::Util::is_pattern_ws( substr( $pattern, $i, 1 ) ) );
    };
    $skip_ws->();
    if( substr( $pattern, $i ) =~ /^(offset:\s*(\d+(?:\.\d+)?))/ )
    {
        $self->{offset} = $2;
        $i += length( $1 );
    }
    my $has_other = 0;
    while(1)
    {
        $skip_ws->();
        last if( $i >= $len );
        my $selector;
        if( substr( $pattern, $i ) =~ /^(=-?\d+(?:\.\d+)?|[A-Za-z_][A-Za-z0-9_\-]*)/ )
        {
            $selector = $1;
            $i += length( $selector );
        }
        else
        {
            $$st = 'U_PATTERN_SYNTAX_ERROR: invalid plural selector in "' . $pattern . '"';
            return;
        }
        $skip_ws->();
        if( $i >= $len || substr( $pattern, $i, 1 ) ne '{' )
        {
            $$st = 'U_PATTERN_SYNTAX_ERROR: missing { after plural selector in "' . $pattern . '"';
            return;
        }
        # Find the matching closing brace, honouring nesting and apostrophe quoting.
        my $start = ++$i;
        my $depth = 1;
        while( $i < $len )
        {
            my $c = substr( $pattern, $i, 1 );
            if( $c eq "'" )
            {
                my $next = $i + 1 < $len ? substr( $pattern, $i + 1, 1 ) : '';
                if( $next eq "'" )
                {
                    $i += 2;
                    next;
                }
                if( $next =~ /^[{}#|]$/ )
                {
                    my $end = index( $pattern, "'", $i + 1 );
                    $i = $end < 0 ? $len : $end + 1;
                    next;
                }
            }
            elsif( $c eq '{' ) { $depth++; }
            elsif( $c eq '}' )
            {
                $depth--;
                last if( !$depth );
            }
            $i++;
        }
        if( $depth )
        {
            $$st = 'U_UNMATCHED_BRACES: in plural pattern "' . $pattern . '"';
            return;
        }
        my $variant = { raw => substr( $pattern, $start, $i - $start ) };
        if( substr( $selector, 0, 1 ) eq '=' )
        {
            $variant->{explicit} = substr( $selector, 1 ) + 0;
        }
        else
        {
            $variant->{keyword} = $selector;
            $has_other = 1 if( $selector eq 'other' );
        }
        push( @{$self->{variants}}, $variant );
        $i++;
    }
    $$st = 'U_DEFAULT_KEYWORD_MISSING: no "other" variant in plural pattern "' . $pattern . '"' if( !$has_other );
    return;
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Locale::Unicode::RBNF::PluralFormat - Plural sub-messages in rule-based number formats

=head1 SYNOPSIS

    use Locale::Unicode::RBNF::PluralFormat;
    my $st;
    my $pf = Locale::Unicode::RBNF::PluralFormat->new( $plural_rules, 'one{st}two{nd}few{rd}other{th}', undef, \$st );
    die( $st ) if( $st );
    say $pf->format( 22, \$st );
    # nd

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Internal module. It handles the plural-only message patterns that rule-based number format rules embed between C<$(> and C<)$>, as ICU C<PluralFormat> does for C<RuleBasedNumberFormat>.

=head1 CONSTRUCTOR

=head2 new

    my $pf = Locale::Unicode::RBNF::PluralFormat->new( $plural_rules, $pattern, $number_format, \$st );

Takes a L<Locale::Unicode::RBNF::PluralRules> object, a plural-only message pattern, a L<Locale::Unicode::RBNF::DecimalFormat> object used to replace C<#> in a sub-message, which may be C<undef>, and a scalar reference that receives an error status, and returns a new object.

The pattern may start with C<offset:> followed by a number, and consists of selectors, either a plural keyword or an explicit value such as C<=0>, each followed by its sub-message between braces. Apostrophe quoting follows the default C<ApostropheMode> of ICU C<MessageFormat>, C<DOUBLE_OPTIONAL>.

The object is always returned. If the pattern is invalid, or has no C<other> variant, the status is set to an error message, and the caller must check it.

=head1 METHODS

=head2 format

    my $string = $pf->format( $number, \$st );

Returns the sub-message selected for the number: an explicit value matching the number takes precedence, then the keyword selected by the plural rules for the number minus the offset, then C<other>. In the sub-message, C<#> is replaced with the number minus the offset, formatted with the decimal format, and apostrophe quoting is resolved.

It returns an empty string if no variant matches.

=head2 parse_type

    my( $begin, $end ) = $pf->parse_type( $source, $rule, $starting_at );

This is ICU C<PluralFormat::parseType()>: it finds, in C<$source>, at or after the position C<$starting_at>, the longest sub-message of the pattern, and returns the positions of its beginning and of its end, or C<( -1, -1 )> if none is found. When a sub-message is not found as is and a rule is given, the lenient matching of that rule, C<$rule>, is tried. As in ICU, the sub-messages of explicit values, such as C<=1>, are never matched.

This method is provided by L<Locale::Unicode::RBNF::PP>, and used by the pure Perl parsing engine.

=head2 to_pattern

Returns the pattern given to L</new>.

=head1 SEE ALSO

L<Locale::Unicode::RBNF>, L<Locale::Unicode::RBNF::PluralRules>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
