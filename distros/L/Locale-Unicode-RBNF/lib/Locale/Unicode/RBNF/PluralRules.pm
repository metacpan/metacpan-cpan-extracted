##----------------------------------------------------------------------------
## Unicode Rule-Based Number Format - ~/lib/Locale/Unicode/RBNF/PluralRules.pm
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
# Evaluator for CLDR plural rules (UTS #35, Part 3, Language Plural Rules), as found in
# common/supplemental/plurals.xml and ordinals.xml
package Locale::Unicode::RBNF::PluralRules;
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
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

# $rules is an array reference of [ keyword, condition ] in the CLDR order.
sub new
{
    my( $this, $rules, $st ) = @_;
    my $self = bless( { rules => [] }, ( ref( $this ) || $this ) );
    foreach my $def ( @{$rules || []} )
    {
        my( $keyword, $condition ) = @$def;
        # Samples, introduced by '@', are not part of the condition.
        $condition =~ s/\@.*$//s;
        $condition =~ s/^\s+|\s+$//g;
        next if( $keyword eq 'other' );
        my $ast = _parse_condition( $condition, $st );
        return( $self ) if( $$st );
        push( @{$self->{rules}}, [ $keyword, $ast ] );
    }
    return( $self );
}

sub keywords
{
    my $self = shift( @_ );
    return( [ ( map( $_->[0], @{$self->{rules}} ) ), 'other' ] );
}

# Returns the plural keyword for a number, given as a number or as a decimal string so that
# visible trailing zeros, such as in "1.50", are taken into account.
sub select
{
    my( $self, $number ) = @_;
    my $op = _operands( $number );
    foreach my $rule ( @{$self->{rules}} )
    {
        return( $rule->[0] ) if( _eval_or( $rule->[1], $op ) );
    }
    return( 'other' );
}

sub _eval_or
{
    my( $or, $op ) = @_;
    foreach my $and ( @$or )
    {
        my $ok = 1;
        foreach my $rel ( @$and )
        {
            if( !_eval_relation( $rel, $op ) )
            {
                $ok = 0;
                last;
            }
        }
        return(1) if( $ok );
    }
    return(0);
}

sub _eval_relation
{
    my( $rel, $op ) = @_;
    my $v = $op->{ $rel->{operand} };
    $v = $v - ( int( $v / $rel->{mod} ) * $rel->{mod} ) if( defined( $rel->{mod} ) );
    my $in = 0;
    foreach my $range ( @{$rel->{ranges}} )
    {
        # A range only contains integers, so 2.5 is not in 2..4
        if( ( @$range == 1 && $v == $range->[0] ) ||
            ( @$range == 2 && $v == int( $v ) && $v >= $range->[0] && $v <= $range->[1] ) )
        {
            $in = 1;
            last;
        }
    }
    return( $rel->{negate} ? !$in : $in );
}

sub _operands
{
    my $number = shift( @_ );
    my $s = "$number";
    $s =~ s/^[+-]//;
    my( $e ) = ( 0 );
    if( $s =~ s/[eEc](-?\d+)$// )
    {
        $e = $1;
        $s = sprintf( '%.15g', $s * ( 10 ** $e ) ) if( $s =~ /\./ || $e );
    }
    my( $int, $frac ) = split( /\./, $s, 2 );
    $frac //= '';
    ( my $trimmed = $frac ) =~ s/0+$//;
    return(
    {
        n => ( $s + 0 ),
        i => ( $int + 0 ),
        v => length( $frac ),
        w => length( $trimmed ),
        f => length( $frac ) ? ( $frac + 0 ) : 0,
        t => length( $trimmed ) ? ( $trimmed + 0 ) : 0,
        c => $e,
        e => $e,
    });
}

# condition = and_condition ( 'or' and_condition )*
sub _parse_condition
{
    my( $condition, $st ) = @_;
    my $or = [];
    return( $or ) if( !length( $condition ) );
    foreach my $and_str ( split( /\s+or\s+/, $condition ) )
    {
        my $and = [];
        foreach my $rel_str ( split( /\s+and\s+/, $and_str ) )
        {
            # relation = operand ( '%' value )? ( '=' | '!=' ) range_list
            if( $rel_str !~ /^\s*([niftvwce])\s*(?:(?:%|mod)\s*(\d+))?\s*(!=|=|is\s+not|is|not\s+in|in|not\s+within|within)\s*(.+?)\s*$/ )
            {
                $$st = 'U_PARSE_ERROR: invalid plural rule relation "' . $rel_str . '"';
                return( $or );
            }
            my( $operand, $mod, $operator, $list ) = ( $1, $2, $3, $4 );
            my @ranges;
            foreach my $item ( split( /\s*,\s*/, $list ) )
            {
                if( $item =~ /^(\d+(?:\.\d+)?)\s*\.\.\s*(\d+(?:\.\d+)?)$/ )
                {
                    push( @ranges, [ $1, $2 ] );
                }
                elsif( $item =~ /^\d+(?:\.\d+)?$/ )
                {
                    push( @ranges, [ $item ] );
                }
                else
                {
                    $$st = 'U_PARSE_ERROR: invalid plural rule range "' . $item . '"';
                    return( $or );
                }
            }
            push( @$and, { operand => $operand, mod => $mod, negate => ( $operator =~ /^(!=|is\s+not|not)/ ? 1 : 0 ), ranges => \@ranges } );
        }
        push( @$or, $and );
    }
    return( $or );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Locale::Unicode::RBNF::PluralRules - CLDR plural rules evaluator

=head1 SYNOPSIS

    use Locale::Unicode::RBNF::PluralRules;
    my $st;
    my $rules = Locale::Unicode::RBNF::PluralRules->new( $cldr->plural_rules( 'fr', 'cardinal' ), \$st );
    die( $st ) if( $st );
    say $rules->select( 2 );
    # other

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Internal module. It evaluates the CLDR cardinal and ordinal plural rules used by the C<$(cardinal,...)$> and C<$(ordinal,...)$> constructs of rule-based number formats.

=head1 CONSTRUCTOR

=head2 new

    my $rules = Locale::Unicode::RBNF::PluralRules->new( [ [ one => 'i = 0,1 @integer 0, 1' ], [ other => '' ] ], \$st );

Takes an array reference of array references C<[ keyword, condition ]>, in the CLDR order, as returned by L<Locale::Unicode::RBNF::CLDR/plural_rules>, and a scalar reference that receives an error status, and returns a new object.

The samples, introduced by C<@>, are ignored, and so is the C<other> rule, since C<other> is what remains when no other rule matches. The operands C<n>, C<i>, C<v>, C<w>, C<f>, C<t>, C<c> and C<e>, the C<%> or C<mod> modulus, and the relations C<=>, C<!=>, C<is>, C<is not>, C<in>, C<not in>, C<within> and C<not within> are supported.

The object is always returned. If a condition cannot be parsed, the status is set to a C<U_PARSE_ERROR> message, and the caller must check it.

=head1 METHODS

=head2 keywords

    my $keywords = $rules->keywords;
    # [ 'one', 'many', 'other' ]

Returns an array reference of the plural keywords, in the order of the rules, followed by C<other>.

=head2 select

    my $keyword = $rules->select( 1 );
    my $keyword = $rules->select( '1.50' );

Returns the plural keyword of the first rule whose condition matches the number, or C<other> if none does.

The number can be given as a decimal string, so that visible trailing zeros, such as in C<1.50>, are taken into account by the operands C<v>, C<w>, C<f> and C<t>. An exponent, such as in C<1.2e3> or C<1.2c3>, is taken into account by the operands C<c> and C<e>.

=head1 SEE ALSO

L<Locale::Unicode::RBNF>, L<Locale::Unicode::RBNF::PluralFormat>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
