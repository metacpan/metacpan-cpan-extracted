package Finance::Alpaca::Struct::TradeActivity 0.9900 {
    use strictures 2;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    #
    use Type::Library 0.008 -base, -declare => qw[TradeActivity];
    use Type::Utils;
    use Types::Standard qw[Enum Num Ref Str];
    use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };
    class_type TradeActivity, { class => __PACKAGE__ };
    coerce( TradeActivity, from Ref() => __PACKAGE__ . q[->new($_)] );
    #
    use Moo;
    use Types::UUID;
    use lib './lib';
    use Finance::Alpaca::Types;
    has activity_type => ( is => 'ro', isa => Str, required => 1 );    # FILL

    has order_id         => ( is => 'ro', isa => Uuid, required => 1 );
    has side             => ( is => 'ro', isa => Enum [qw[buy sell sell_short]], required => 1 );
    has transaction_time => ( is => 'ro', isa => Timestamp, required => 1, coerce => 1 );

    has [qw[symbol id]]                     => ( is => 'ro', isa => Str, required => 1 );
    has [qw[qty cum_qty leaves_qty price ]] => ( is => 'ro', isa => Num, required => 1 );
    has type => ( is => 'ro', isa => Enum [qw[fill partial_fill]], required => 1 );
}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::Struct::TradeActivity - A Single Trade Activity Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    my @activities = Finance::Alpaca->new( ... )->activities;

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

=item C<activity_type> - C<FILL>

=item C<cum_qty> - The cumulative quantity of shares involved in the execution

=item C<leaves_qty> - For C<partially_filled> orders, the quantity of shares that are left to be filled

=item C<price> - The per-share price that the trade was executed at

=item C<qty> - The number of shares involved in the trade execution

=item C<side> - C<buy>, C<sell>, or C<sell_short>

=item C<symbol> - The symbol of the security being traded

=item C<transaction_time> - Timestamp at which the execution occurred as a Time::Moment object

=item C<order_id> - The id (UUID) for the order that filled

=item C<type> - C<fill> or C<partial_fill>

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
