package Finance::Alpaca::Struct::Activity 0.9900 {
    use strictures 2;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    #
    use Type::Library 0.008 -base, -declare => qw[Activity];
    use Type::Utils;
    use Types::Standard qw[Enum Num Ref Str];
    use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };
    class_type Activity, { class => __PACKAGE__ };
    coerce( Activity, from Ref() => __PACKAGE__ . q[->new($_)] );
    #
    use Moo;
    use Types::UUID;
    use lib './lib';
    use Finance::Alpaca::Types;
    has activity_type => (
        is  => 'ro',
        isa => Enum [
            qw[FILL TRANS MISC ACATC ACATS CSD CSW DIV DIVCGL DIVCGS DIVFEE
                DIVFT DIVNRA DIVROC DIVTW DIVTXEX INT INTNRA INTTW JNL JNLC JNLS
                MA NC OPASN OPEXP OPXRC PTC PTR REORG SC SSO SSP]
        ],
        required => 1
    );
    has date                       => ( is => 'ro', isa => Timestamp, required  => 1, coerce => 1 );
    has net_amount                 => ( is => 'ro', isa => Num,       required  => 1 );
    has [qw[id symbol]]            => ( is => 'ro', isa => Str,       required  => 1 );
    has [qw[qty per_share_amount]] => ( is => 'ro', isa => Num,       predicate => 1 );
}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::Struct::Activity - A Single Account Activity Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    for my $activity (Finance::Alpaca->new( ... )->activities( activity_types => [qw[ACATC ACATS]] )) {
        say sprintf '%s @ %f', $activity->symbol, $activity->net_amount
    }

=head1 DESCRIPTION

The account activities API provides access to a historical record of
transaction activities that have impacted your account. Trade execution
activities and non-trade activities, such as dividend payments, are both
reported through this endpoint. See the bottom of this page for a full list of
the types of activities that may be reported.

=head1 Properties

The following properties are contained in the object.

    for my $activity ($camelia->activities()) {
        say $activity->symbol;
    }

=over

=item C<id> - An ID for the activity, always in “::” format. Can be sent as C<page_token> in requests to facilitate the paging of results.

=item C<activity_type> - See below for a list of possible values

=item C<date> - The date on which the activity occurred or on which the transaction associated with the activity settled as a Time::Moment object

=item C<net_amount> - The net amount of money (positive or negative) associated with the activity

=item C<symbol> - The symbol of the security involved with the activity. Not present for all activity types

=item C<qty> - For dividend activities, the number of shares that contributed to the payment. Not present for other activity types

=item C<per_share_amount> - For dividend activities, the average amount paid per share. Not present for other activity types

=back

=head1 Activity Types

=over

=item C<FILL> - Order fills (both partial and full fills)

=item C<TRANS> - Cash transactions (both CSD and CSW)

=item C<MISC> - Miscellaneous or rarely used activity types (All types except those in TRANS, DIV, or FILL)

=item C<ACATC> - ACATS IN/OUT (Cash)

=item C<ACATS> - ACATS IN/OUT (Securities)

=item C<CSD> - Cash deposit(+)

=item C<CSW> - Cash withdrawal(-)

=item C<DIV> - Dividends

=item C<DIVCGL> - Dividend (capital gain long term)

=item C<DIVCGS> - Dividend (capital gain short term)

=item C<DIVFEE> - Dividend fee

=item C<DIVFT> - Dividend adjusted (Foreign Tax Withheld)

=item C<DIVNRA> - Dividend adjusted (NRA Withheld)

=item C<DIVROC> - Dividend return of capital

=item C<DIVTW> - Dividend adjusted (Tefra Withheld)

=item C<DIVTXEX> - Dividend (tax exempt)

=item C<INT> - Interest (credit/margin)

=item C<INTNRA> - Interest adjusted (NRA Withheld)

=item C<INTTW> - Interest adjusted (Tefra Withheld)

=item C<JNL> - Journal entry

=item C<JNLC> - Journal entry (cash)

=item C<JNLS> - Journal entry (stock)

=item C<MA> - Merger/Acquisition

=item C<NC> - Name change

=item C<OPASN> - Option assignment

=item C<OPEXP> - Option expiration

=item C<OPXRC> - Option exercise

=item C<PTC> - Pass Thru Charge

=item C<PTR> - Pass Thru Rebate

=item C<REORG> - Reorg CA

=item C<SC> - Symbol change

=item C<SSO> - Stock spinoff

=item C<SSP> - Stock split

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

# https://alpaca.markets/docs/api-documentation/api-v2/account-activities/
