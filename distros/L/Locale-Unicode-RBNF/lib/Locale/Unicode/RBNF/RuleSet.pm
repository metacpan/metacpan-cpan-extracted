##----------------------------------------------------------------------------
## Unicode Rule-Based Number Format - ~/lib/Locale/Unicode/RBNF/RuleSet.pm
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
# Port of ICU4C NFRuleSet (icu4c/source/i18n/nfrs.cpp, ICU 79.1)
package Locale::Unicode::RBNF::RuleSet;
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
    use vars qw( $VERSION $RECURSION_LIMIT );
    use POSIX ();
    use Scalar::Util qw( weaken );
    use Locale::Unicode::RBNF::Rule;
    use Locale::Unicode::RBNF::Util qw( :all );
    use constant {
        NEGATIVE_RULE_INDEX             => 0,
        IMPROPER_FRACTION_RULE_INDEX    => 1,
        PROPER_FRACTION_RULE_INDEX      => 2,
        DEFAULT_RULE_INDEX              => 3,
        INFINITY_RULE_INDEX             => 4,
        NAN_RULE_INDEX                  => 5,
        NON_NUMERICAL_RULE_LENGTH       => 6,
    };
    $RECURSION_LIMIT = 64;
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

# The constructor only extracts the rule set name from its description; the rules themselves
# are parsed later by parse_rules(), once the names of all the rule sets are known.
sub new
{
    my( $this, $owner, $descriptions, $index, $st ) = @_;
    my $self = bless(
    {
        name                => '',
        rules               => [],
        non_numerical_rules => [ (undef) x NON_NUMERICAL_RULE_LENGTH ],
        owner               => $owner,
        fraction_rules      => [],
        is_fraction         => 0,
        is_public           => 0,
        is_parseable        => 1,
    }, ( ref( $this ) || $this ) );
    weaken( $self->{owner} );
    return( $self ) if( $$st );
    my $description = \$descriptions->[ $index ];
    if( !length( $$description ) )
    {
        $$st = 'U_PARSE_ERROR: empty rule set description';
        return( $self );
    }
    if( substr( $$description, 0, 1 ) eq '%' )
    {
        my $pos = index( $$description, ':' );
        # No name, or the name is just "%"
        if( $pos < 2 )
        {
            $$st = 'U_PARSE_ERROR: rule set name does not end in a colon';
            return( $self );
        }
        $self->{name} = substr( $$description, 0, $pos );
        1 while( $pos < length( $$description ) && is_pattern_ws( substr( $$description, ++$pos, 1 ) ) );
        substr( $$description, 0, $pos, '' );
    }
    else
    {
        $self->{name} = '%default';
    }
    if( !length( $$description ) )
    {
        $$st = 'U_PARSE_ERROR: empty rule set description';
        return( $self );
    }
    $self->{is_public} = index( $self->{name}, '%%' ) == 0 ? 0 : 1;
    if( length( $self->{name} ) >= 8 && substr( $self->{name}, -8 ) eq '@noparse' )
    {
        $self->{is_parseable} = 0;
        substr( $self->{name}, -8, 8, '' );
    }
    return( $self );
}

sub find_double_rule
{
    my( $self, $number ) = @_;
    return( $self->_find_fraction_rule_set_rule( $number ) ) if( $self->{is_fraction} );
    my $nnr = $self->{non_numerical_rules};
    if( is_nan( $number ) )
    {
        return( $nnr->[ NAN_RULE_INDEX ] // $self->{owner}->{default_nan_rule} );
    }
    # A negative number without a negative-number rule is treated as positive.
    if( $number < 0 )
    {
        return( $nnr->[ NEGATIVE_RULE_INDEX ] ) if( $nnr->[ NEGATIVE_RULE_INDEX ] );
        $number = -$number;
    }
    if( is_infinite( $number ) )
    {
        return( $nnr->[ INFINITY_RULE_INDEX ] // $self->{owner}->{default_infinity_rule} );
    }
    # A non-integer uses one of the fraction rules.
    if( $number != POSIX::floor( $number ) )
    {
        if( $number < 1 && $nnr->[ PROPER_FRACTION_RULE_INDEX ] )
        {
            return( $nnr->[ PROPER_FRACTION_RULE_INDEX ] );
        }
        elsif( $nnr->[ IMPROPER_FRACTION_RULE_INDEX ] )
        {
            return( $nnr->[ IMPROPER_FRACTION_RULE_INDEX ] );
        }
    }
    return( $nnr->[ DEFAULT_RULE_INDEX ] ) if( $nnr->[ DEFAULT_RULE_INDEX ] );
    return( $self->_find_normal_rule( from_double( $number + 0.5 ) ) );
}

sub format_double
{
    my( $self, $number, $out, $pos, $rc, $st ) = @_;
    if( $rc >= $RECURSION_LIMIT )
    {
        $$st = 'U_INVALID_STATE_ERROR: recursion limit reached in rule set ' . $self->{name};
        return;
    }
    my $rule = $self->find_double_rule( $number );
    $rule->do_format_double( $number, $out, $pos, ++$rc, $st ) if( $rule );
    return;
}

sub format_int
{
    my( $self, $number, $out, $pos, $rc, $st ) = @_;
    if( $rc >= $RECURSION_LIMIT )
    {
        $$st = 'U_INVALID_STATE_ERROR: recursion limit reached in rule set ' . $self->{name};
        return;
    }
    my $rule = $self->_find_normal_rule( $number );
    $rule->do_format_int( $number, $out, $pos, ++$rc, $st ) if( $rule );
    return;
}

sub get_name { return( $_[0]->{name} ); }

sub get_owner { return( $_[0]->{owner} ); }

sub is_fraction_rule_set { return( $_[0]->{is_fraction} ); }

sub is_named { return( $_[0]->{name} eq $_[1] ? 1 : 0 ); }

sub is_parseable { return( $_[0]->{is_parseable} ); }

sub is_public { return( $_[0]->{is_public} ); }

sub make_into_fraction_rule_set { $_[0]->{is_fraction} = 1; return; }

# NFRuleSet::parseRules()
sub parse_rules
{
    my( $self, $description, $st ) = @_;
    return if( $$st );
    $self->{rules} = [];
    # The rules are separated by semicolons; there is no escape facility.
    my $old_p = 0;
    my $len = length( $description );
    while( $old_p < $len )
    {
        my $p = index( $description, ';', $old_p );
        $p = $len if( $p == -1 );
        my $rules = $self->{rules};
        Locale::Unicode::RBNF::Rule->make_rules( substr( $description, $old_p, $p - $old_p ), $self, ( @$rules ? $rules->[-1] : undef ), $self->{owner}, $rules, $st );
        return if( $$st );
        $old_p = $p + 1;
    }
    # Rules without an explicit base value get 1 plus the preceding rule's base value, or the
    # same base value in a fraction rule set.
    my $default_base = 0;
    foreach my $rule ( @{$self->{rules}} )
    {
        my $base = $rule->get_base_value;
        if( $base == 0 )
        {
            $rule->set_base_value( $default_base, $st );
            return if( $$st );
        }
        else
        {
            if( $base < $default_base )
            {
                $$st = 'U_PARSE_ERROR: rules are not in order in rule set ' . $self->{name};
                return;
            }
            $default_base = $base;
        }
        ++$default_base if( !$self->{is_fraction} );
    }
    return;
}

# Determines the best fraction rule to use: rules matching the decimal separator of the
# decimal format symbols become the main ones.
sub set_best_fraction_rule
{
    my( $self, $original_index, $new_rule, $remember ) = @_;
    push( @{$self->{fraction_rules}}, $new_rule ) if( $remember );
    my $best = $self->{non_numerical_rules}->[ $original_index ];
    if( !$best )
    {
        $self->{non_numerical_rules}->[ $original_index ] = $new_rule;
    }
    else
    {
        my $sym = $self->{owner}->{symbols};
        my $dec = $sym ? substr( $sym->{decimal} // '', 0, 1 ) : '';
        $self->{non_numerical_rules}->[ $original_index ] = $new_rule if( length( $dec ) && $dec eq $new_rule->get_decimal_point );
    }
    return;
}

sub set_decimal_format_symbols
{
    my( $self, $symbols, $st ) = @_;
    $_->set_decimal_format_symbols( $symbols, $st ) for( @{$self->{rules}} );
    # Switch the fraction rules to mirror the decimal format symbols.
    my $nnr = $self->{non_numerical_rules};
    for my $idx ( IMPROPER_FRACTION_RULE_INDEX..DEFAULT_RULE_INDEX )
    {
        next if( !$nnr->[ $idx ] );
        foreach my $fraction_rule ( @{$self->{fraction_rules}} )
        {
            $self->set_best_fraction_rule( $idx, $fraction_rule, 0 ) if( $nnr->[ $idx ]->get_base_value == $fraction_rule->get_base_value );
        }
    }
    $_->set_decimal_format_symbols( $symbols, $st ) for( grep( defined( $_ ), @$nnr ) );
    return;
}

sub set_non_numerical_rule
{
    my( $self, $rule ) = @_;
    my $bv = $rule->get_base_value;
    if( $bv == Locale::Unicode::RBNF::Rule::NEGATIVE_NUMBER )
    {
        $self->{non_numerical_rules}->[ NEGATIVE_RULE_INDEX ] = $rule;
    }
    elsif( $bv == Locale::Unicode::RBNF::Rule::IMPROPER_FRACTION )
    {
        $self->set_best_fraction_rule( IMPROPER_FRACTION_RULE_INDEX, $rule, 1 );
    }
    elsif( $bv == Locale::Unicode::RBNF::Rule::PROPER_FRACTION )
    {
        $self->set_best_fraction_rule( PROPER_FRACTION_RULE_INDEX, $rule, 1 );
    }
    elsif( $bv == Locale::Unicode::RBNF::Rule::DEFAULT_RULE )
    {
        $self->set_best_fraction_rule( DEFAULT_RULE_INDEX, $rule, 1 );
    }
    elsif( $bv == Locale::Unicode::RBNF::Rule::INFINITY_RULE )
    {
        $self->{non_numerical_rules}->[ INFINITY_RULE_INDEX ] = $rule;
    }
    elsif( $bv == Locale::Unicode::RBNF::Rule::NAN_RULE )
    {
        $self->{non_numerical_rules}->[ NAN_RULE_INDEX ] = $rule;
    }
    # Any other rule is not remembered, and is simply discarded.
    return;
}

# NFRuleSet::appendRules()
sub to_string
{
    my $self = shift( @_ );
    my $result = $self->{name} . ":\n";
    $result .= $_->to_string . "\n" for( @{$self->{rules}} );
    foreach my $rule ( @{$self->{non_numerical_rules}} )
    {
        next if( !$rule );
        my $bv = $rule->get_base_value;
        if( $bv == Locale::Unicode::RBNF::Rule::IMPROPER_FRACTION ||
            $bv == Locale::Unicode::RBNF::Rule::PROPER_FRACTION ||
            $bv == Locale::Unicode::RBNF::Rule::DEFAULT_RULE )
        {
            foreach my $fraction_rule ( @{$self->{fraction_rules}} )
            {
                $result .= $fraction_rule->to_string . "\n" if( $fraction_rule->get_base_value == $bv );
            }
        }
        else
        {
            $result .= $rule->to_string . "\n";
        }
    }
    return( $result );
}

# NFRuleSet::findFractionRuleSetRule(): each base value is treated as a denominator, and the
# one producing the fraction closest to the number wins. The computation is done with the
# least common multiple of the denominators, in integer arithmetic, to avoid rounding errors.
sub _find_fraction_rule_set_rule
{
    my( $self, $number ) = @_;
    my $rules = $self->{rules};
    return if( !@$rules );
    my $lcm = $rules->[0]->get_base_value;
    return if( $lcm == 0 );
    for( my $i = 1; $i < scalar( @$rules ); ++$i )
    {
        $lcm = lcm( $lcm, $rules->[$i]->get_base_value );
    }
    my $numerator = from_double( $number * $lcm + 0.5 );
    my $difference = from_double( $Locale::Unicode::RBNF::Util::MAX_MANTISSA );
    my $winner = 0;
    for( my $i = 0; $i < scalar( @$rules ); ++$i )
    {
        my $temp;
        {
            use integer;
            $temp = $numerator * $rules->[$i]->get_base_value % $lcm;
        }
        # We want the numerator's distance from the closest multiple of the LCD.
        $temp = $lcm - $temp if( $lcm - $temp < $temp );
        if( $temp < $difference )
        {
            $difference = $temp;
            $winner = $i;
            last if( $difference == 0 );
        }
    }
    # With two successive rules having the winning base value, the first one is used when the
    # numerator is 1 and the second one otherwise ("one third" and "two thirds").
    if( $winner + 1 < scalar( @$rules ) && $rules->[ $winner + 1 ]->get_base_value == $rules->[ $winner ]->get_base_value )
    {
        my $n = $rules->[ $winner ]->get_base_value * $number;
        ++$winner if( $n < 0.5 || $n >= 2 );
    }
    return( $rules->[ $winner ] );
}

sub _find_normal_rule
{
    my( $self, $number ) = @_;
    # In a fraction rule set, we should only get here if the value is 0.
    return( $self->_find_fraction_rule_set_rule( $number + 0.0 ) ) if( $self->{is_fraction} );
    my $nnr = $self->{non_numerical_rules};
    if( $number < 0 )
    {
        return( $nnr->[ NEGATIVE_RULE_INDEX ] ) if( $nnr->[ NEGATIVE_RULE_INDEX ] );
        $number = -$number;
    }
    # Binary search for the applicable rule: a rule is used for all values from its base value
    # to the next rule's base value.
    my $rules = $self->{rules};
    my $hi = scalar( @$rules );
    if( $hi > 0 )
    {
        my $lo = 0;
        while( $lo < $hi )
        {
            my $mid = int( ( $lo + $hi ) / 2 );
            my $bv = $rules->[ $mid ]->{base_value};
            return( $rules->[ $mid ] ) if( $bv == $number );
            if( $bv > $number ) { $hi = $mid; }
            else { $lo = $mid + 1; }
        }
        # Bad rule set: the minimum base value is above 0.
        return if( $hi == 0 );
        my $result = $rules->[ $hi - 1 ];
        if( $result->should_roll_back( $number ) )
        {
            # Bad rule set: there is no prior rule to roll back to.
            return if( $hi == 1 );
            $result = $rules->[ $hi - 2 ];
        }
        return( $result );
    }
    # If there are no rules, the default rule is used.
    return( $nnr->[ DEFAULT_RULE_INDEX ] );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Locale::Unicode::RBNF::RuleSet - A rule set of a rule-based number format

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Internal module. This is a port of ICU4C C<NFRuleSet> (F<nfrs.cpp>, ICU 79.1).

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

The indices of the special rules in the array of non-numerical rules, as in ICU C<NFRuleSet>: C<NEGATIVE_RULE_INDEX> (0), C<IMPROPER_FRACTION_RULE_INDEX> (1), C<PROPER_FRACTION_RULE_INDEX> (2), C<DEFAULT_RULE_INDEX> (3), C<INFINITY_RULE_INDEX> (4), C<NAN_RULE_INDEX> (5), and C<NON_NUMERICAL_RULE_LENGTH> (6), the size of that array.

The variable C<$RECURSION_LIMIT> is the maximum recursion depth of formatting and parsing, 64 as in ICU.

=head1 CONSTRUCTOR

=head2 new

    my $rule_set = Locale::Unicode::RBNF::RuleSet->new( $formatter, \@descriptions, $index, \$st );

Takes the L<Locale::Unicode::RBNF> object that owns the rule set, an array reference of rule set descriptions, the index of the description of this rule set, and a scalar reference that receives an error status.

The constructor only extracts the name of the rule set, such as C<%spellout-numbering>, or C<%default> if the description has none, and removes it from the description in the array. A name starting with C<%%> makes the rule set private, and a name ending with C<@noparse> makes it unparseable; that suffix is removed from the name. The rules themselves are parsed later by L</parse_rules>, once the names of all the rule sets are known, since rules can refer to any of them.

The formatter is kept as a weak reference.

=head1 METHODS

=head2 find_double_rule

    my $rule = $rule_set->find_double_rule( $number );

This is ICU C<NFRuleSet::findDoubleRule()>: it returns the rule to use for a double, that is the C<NaN>, negative-number, infinity, fraction or default rule when applicable, or otherwise the normal rule for the number rounded to the nearest integer. In a fraction rule set, the rule giving the closest fraction is returned.

=head2 format_double

    $rule_set->format_double( $number, $out, $pos, $rc, $st );

Formats a double with the rule returned by L</find_double_rule>. If the recursion limit is reached, C<$st> is set to a C<U_INVALID_STATE_ERROR> message.

=head2 format_int

    $rule_set->format_int( $number, $out, $pos, $rc, $st );

Formats an integer with the normal rule applicable to it, found by binary search, honouring L<Locale::Unicode::RBNF::Rule/should_roll_back>. If the recursion limit is reached, C<$st> is set to a C<U_INVALID_STATE_ERROR> message.

=head2 get_name

Returns the name of the rule set, including its leading C<%> or C<%%>.

=head2 get_owner

Returns the L<Locale::Unicode::RBNF> object that owns the rule set.

=head2 is_fraction_rule_set

Returns true if the rule set is a fraction rule set, that is one used by a fractional part substitution such as C<< >%%frac> >>, whose rules represent denominators.

=head2 is_named

    my $bool = $rule_set->is_named( '%spellout-cardinal' );

Returns true if the rule set has the name given.

=head2 is_parseable

Returns true if the rule set takes part in parsing.

=head2 is_public

Returns true if the rule set is public, that is if its name does not start with C<%%>.

=head2 make_into_fraction_rule_set

Marks the rule set as a fraction rule set. This is called by the fractional part substitutions that use it.

=head2 parse

    my( $success, $value ) = $rule_set->parse( $text, $pp, $upper_bound, $mask, $rc );

This is ICU C<NFRuleSet::parse()>: it matches the text against the non-numerical rules not yet executed according to C<$mask>, then against the normal rules, from the most significant one, skipping, except in a fraction rule set, those whose base value is not below C<$upper_bound>. It keeps the result of the rule that matched the most characters, and returns a list of 2 elements: whether something was matched, and the value parsed. C<$pp> is updated with the position reached.

This method is provided by L<Locale::Unicode::RBNF::PP>, and used by the pure Perl parsing engine.

=head2 parse_rules

    $rule_set->parse_rules( $description, \$st );

This is ICU C<NFRuleSet::parseRules()>: it divides the description into rules at the semicolons, creates them with L<Locale::Unicode::RBNF::Rule/make_rules>, gives the rules without an explicit base value the base value of the preceding rule plus 1, or the same base value in a fraction rule set, and checks that the base values are in ascending order.

=head2 set_best_fraction_rule

    $rule_set->set_best_fraction_rule( $index, $rule, $remember );

Determines the fraction rule to use at the given index of the non-numerical rules, when the rule set has several, such as C<x.x> and C<x,x>: the rule whose decimal point is the decimal separator of the decimal format symbols becomes the one in use. If C<$remember> is true, the rule is also added to the list of fraction rules, so that the choice can be made again when the symbols change.

=head2 set_decimal_format_symbols

    $rule_set->set_decimal_format_symbols( $symbols, \$st );

Passes new decimal format symbols to the rules, and selects again the fraction rules that match the new decimal separator, with L</set_best_fraction_rule>.

=head2 set_non_numerical_rule

    $rule_set->set_non_numerical_rule( $rule );

Stores a non-numerical rule, that is a negative-number, fraction, default, infinity or C<NaN> rule, at its index, according to its base value.

=head2 to_string

Returns the description of the rule set in the ICU syntax: its name followed by a colon, then each rule on its own line, as ICU C<NFRuleSet::appendRules()> produces it. This is used by L<Locale::Unicode::RBNF/rules>.

=head1 SEE ALSO

L<Locale::Unicode::RBNF>, L<Locale::Unicode::RBNF::Rule>, L<Locale::Unicode::RBNF::Substitution>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

Portions are derived from ICU, Copyright (C) 2016 and later Unicode, Inc. and others, under the Unicode License (L<https://www.unicode.org/copyright.html>). Its text is in the F<LICENSE-UNICODE> file of this distribution.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
