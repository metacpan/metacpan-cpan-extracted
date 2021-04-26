package Finance::Alpaca::Struct::Account 0.9900 {
    use strictures 2;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    #
    use Type::Library 0.008 -base, -declare => qw[Account];
    use Type::Utils;
    use Types::Standard qw[Bool Enum Int Num Ref Str];
    use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };
    class_type Account, { class => __PACKAGE__ };
    coerce( Account, from Ref() => __PACKAGE__ . q[->new($_)] );
    #
    use Moo;
    use Types::UUID;
    use lib './lib';
    use Finance::Alpaca::Types;
    has id => ( is => 'ro', isa => Uuid, required => 1 );
    has [
        qw[account_blocked pattern_day_trader shorting_enabled trade_suspended_by_user trading_blocked transfers_blocked]
    ] => ( is => 'ro', isa => Bool, required => 1, coerce => 1 );
    has account_number => ( is => 'ro', isa => Str, required => 1 );
    has [
        qw[buying_power cash daytrading_buying_power equity initial_margin last_equity last_maintenance_margin long_market_value maintenance_margin portfolio_value regt_buying_power short_market_value]
    ] => ( is => 'ro', isa => Num, required => 1 );
    has created_at => ( is => 'ro', isa => Timestamp, required => 1, coerce => 1 );
    has currency                            => ( is => 'ro', isa => Str, required => 1 );
    has [qw[daytrade_count multiplier sma]] => ( is => 'ro', isa => Int, required => 1 );
    has status                              => (
        is  => 'ro',
        isa => Enum [
            qw[ACTIVE ACCOUNT_UPDATED APPROVAL_PENDING ONBOARDING REJECTED SUBMITTED SUBMISSION_FAILED]
        ],
        required => 1
    );
    #
}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::Struct::Account - A Single Account Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    my $acct = Finance::Alpaca->new( ... )->account;
    say sprintf 'I can%s short!', $acct->shorting_enabled ? '' : 'not';

=head1 DESCRIPTION

The account API serves important information related to an account, including
account status, funds available for trade, funds available for withdrawal, and
various flags relevant to an account’s ability to trade. An account maybe be
blocked for just for trades (trades_blocked flag) or for both trades and
transfers (account_blocked flag) if Alpaca identifies the account to engaging
in any suspicious activity. Also, in accordance with FINRA’s pattern day
trading rule, an account may be flagged for pattern day trading
(pattern_day_trader  flag), which would inhibit an account from placing any
further day-trades.

=head1 Properties

The following properties are contained in the object.

    $account->id()

=over

=item C<id> - UUID

=item C<account_number> - Account number

=item C<status> - See Account Status

=item C<currency> - String (USD)

=item C<cash> - Cash balance

=item C<pattern_day_trader> - Boolean indicating whether or not the account has been flagged as a pattern day trader

=item C<trade_suspended_by_user> - Boolean indicating whether the account is allowed to place orders (Defined by the user)

=item C<trading_blocked> - Boolean indicating whether the account is allowed to place orders (Defined by the system)

=item C<account_blocked> - Boolean indicating the account activity by the user is prohibited

=item C<created_at> - Timestamp this account was created at

=item C<shorting_enabled> - Boolean indicating whether or not the account is permitted to short

=item C<long_market_value> - Real-time MtM value of all long positions held in the account

=item C<short_market_value> - Real-time MtM value of all short positions held in the account

=item C<equity> - Cash + long_market_value + short_market_value

=item C<last_equity> - Equity as of previous trading day at 16:00:00 ET

=item C<multiplier> - Buying power multiplier that represents account margin classification; valid values 1 (standard limited margin account with 1x buying power), 2 (reg T margin account with 2x intraday and overnight buying power; this is the default for all non-PDT accounts with $2,000 or more equity), 4 (PDT account with 4x intraday buying power and 2x reg T overnight buying power)

=item C<buying_power> - Current available $ buying power; If multiplier = 4, this is your daytrade buying power which is calculated as (last_equity - (last) maintenance_margin) * 4; If multiplier = 2, buying_power = max(equity – initial_margin,0) * 2; If multiplier = 1, buying_power = cash

=item C<initial_margin> - Reg T initial margin requirement (continuously updated value)

=item C<maintenance_margin> - Maintenance margin requirement (continuously updated value)

=item C<sma> - Value of special memorandum account (will be used at a later date to provide additional buying_power)

=item C<daytrade_count> - The current number of daytrades that have been made in the last five trading days (inclusive of today)

=item C<last_maintenance_margin> - Your maintenance marign requirement on the previous trading day

=item C<daytrading_buying_power> - Your buying power for day trades (continuously updated value)

=item C<regt_buying_power> -  Your buying power under Regulation T (your excess equity - equity - margin value * your margin multiplier)

=back

=head1 Account Status

The following are the possible account status values. Most likely, the account
status is C<ACTIVE> unless there is any problem. The account status may get in
C<ACCOUNT_UPDATED> when personal information is being updated from the
dashboard,  in which case you may not be allowed trading for a short period of
time until  the change is approved.

=over

=item C<ONBOARDING> - The account is onboarding.

=item C<SUBMISSION_FAILED> - The account application submission failed for some reason.

=item C<SUBMITTED> - The account application has been submitted for review.

=item C<ACCOUNT_UPDATED> - The account information is being updated.

=item C<APPROVAL_PENDING> - The final account approval is pending.

=item C<ACTIVE> - The account is active for trading.

=item C<REJECTED> - The account application has been rejected.

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

# https://alpaca.markets/docs/api-documentation/api-v2/account/
