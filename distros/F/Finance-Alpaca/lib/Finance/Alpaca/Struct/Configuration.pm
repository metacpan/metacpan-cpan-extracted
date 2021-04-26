package Finance::Alpaca::Struct::Configuration 0.9900 {
    use strictures 2;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    #
    use Type::Library 0.008 -base, -declare => qw[Configuration];
    use Type::Utils;
    use Types::Standard qw[Bool Enum Num Ref Str];
    use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };
    class_type Configuration, { class => __PACKAGE__ };
    coerce( Configuration, from Ref() => __PACKAGE__ . q[->new($_)] );
    #
    use Moo;
    use lib './lib';
    has dtbp_check          => ( is => 'ro', isa => Enum [qw[both entry exit]], required => 1 );
    has trade_confirm_email => ( is => 'ro', isa => Enum [qw[all none]],        required => 1 );
    has [qw[fractional_trading no_shorting suspend_trade]] =>
        ( is => 'ro', isa => Bool, required => 1, coerce => 1 );
    has max_margin_multiplier => ( is => 'ro', isa => Num, required => 1 );
}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::Struct::Configuration - A Single Account Configuration Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    my $config = Finance::Alpaca->new( ... )->configuration;

=head1 DESCRIPTION

The account configuration API provides custom configurations about your trading
account settings. These configurations control various allow you to modify
settings to suit your trading needs.

For DTMC protection, see L<Day Trade Margin Call
Protection|https://alpaca.markets/docs/trading-on-alpaca/user-protections/#day-trade-margin-call-dtmc-protection-at-alpaca>

=head1 Properties

The following properties are contained in the object.

    say sprintf 'Can%s trade with this account', $config->suspend_trade ? 'not' : '';

=over

=item C<dtbp_check> - C<both>, C<entry>, or C<exit>. Controls Day Trading Margin Call (DTMC) checks

=item C<trade_confirm_email> - C<all> or C<none>. If C<none>, emails for order fills are not sent

=item C<syspend_trade> - If true, new orders are blocked

=item C<no_shorting> - If true, account becomes long-only mode

=item C<fractional_trading> - If true, account can trade fractions of shares

=item C<max_margin_multiplier> - Leverage

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

# https://alpaca.markets/docs/api-documentation/api-v2/account-configuration/
