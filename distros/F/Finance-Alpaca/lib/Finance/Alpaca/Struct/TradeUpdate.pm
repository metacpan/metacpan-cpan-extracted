package Finance::Alpaca::Struct::TradeUpdate 0.9900 {
    use strictures 2;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    #
    use Type::Library 0.008 -base, -declare => qw[TradeUpdate];
    use Type::Utils;
    use Types::Standard qw[Enum Num Ref Str];
    use Types::TypeTiny 0.004 StringLike => { -as => "Stringable" };
    class_type TradeUpdate, { class => __PACKAGE__ };
    coerce( TradeUpdate, from Ref() => __PACKAGE__ . q[->new($_)] );
    #
    use Moo;
    use Types::UUID;
    use lib './lib';
    use Finance::Alpaca::Types;
    use Finance::Alpaca::Struct::Order qw[Order];
    has event => (
        is  => 'ro',
        isa => Enum [
            qw[
                new fill partial_fill canceled expired done_for_day replaced
                rejected pending_new stopped pending_cancel pending_replace
                calculated suspended
                order_replace_rejected order_cancel_rejected]
        ],
        required => 1
    );
    has order     => ( is => 'ro', isa => Order,     required  => 1, coerce => 1 );
    has timestamp => ( is => 'ro', isa => Timestamp, predicate => 1, coerce => 1 );
    has [qw[position_qty price qty]] => ( is => 'ro', isa => Num, predicate => 1 );
}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::Struct::TradeUpdate - A Single Streamed Data Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    my $stream = Finance::Alpaca->new( ... )->trade_stream(
        sub ($event) {
            ...
        }
     );
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

=head1 DESCRIPTION

Alpaca’s API offers WebSocket streaming for account and order updates. When
subscribed, events returned from Alpaca will be coerced into
Finance::Alpaca::Struct::Stream objects.

=head1 Properties

The fields present in a message depend on the type of event they are
communicating. All messages contain an event C<type> and an C<order> field,
which is the same as the order object that is returned from the REST API.
Potential event types and additional fields that will be in their messages are
listed below.

=head2 Common events

These are the events that are the expected results of actions you may have
taken by sending API requests.

=over

=item C<new> - Sent when an order has been routed to exchanges for execution

=item C<fill> - Sent when your order has been completely filled

=over

=item C<timestamp> - The time at which the order was filled

=item C<price> The average price per share at which the order was filled

=item C<position_qty> The size of your total position, after this fill event, in shares. Positive for long positions, negative for short positions

=back

=item C<partial_fill> Sent when a number of shares less than the total remaining quantity on your order has been filled.

=over

=item C<timestamp> The time at which the shares were filled

=item C<price> The average price per share at which the shares were filled

=item C<position_qty> The size of your total position, after this fill event, in shares. Positive for long positions, negative for short positions

=back

=item C<canceled> Sent when your requested cancelation of an order is processed

=over

=item C<timestamp> The time at which the order was canceled

=back

=item C<expired> Sent when an order has reached the end of its lifespan, as determined by the order’s time in force value

=over

=item C<timestamp> The time at which the order expired

=back

=item C<done_for_day> Sent when the order is done executing for the day, and will not receive further updates until the next trading day

=item C<replaced> Sent when your requested replacement of an order is processed

=over

=item C<timestamp> The time at which the order was replaced.

=back

=back

=head2 C<Rarer events>

These are events that may rarely be sent due to unexpected circumstances on the
exchanges. It is unlikely you will need to design your code around them, but
you may still wish to account for the possibility that they will occur.

=over

=item C<rejected> - Sent when your order has been rejected

=over

=item C<timestamp> - The time at which the rejection occurred

=back

=item C<pending_new> - Sent when the order has been received by Alpaca and routed to the exchanges, but has not yet been accepted for execution

=item C<stopped> - Sent when your order has been stopped, and a trade is guaranteed for the order, usually at a stated price or better, but has not yet occurred

=item C<pending_cancel> - Sent when the order is awaiting cancelation. Most cancelations will occur without the order entering this state

=item C<pending_replace> - Sent when the order is awaiting replacement

=item C<calculated> - Sent when the order has been completed for the day - it is either “filled” or “done_for_day” - but remaining settlement calculations are still pending

=item C<suspended> - Sent when the order has been suspended and is not eligible for trading

=item C<order_replace_rejected> - Sent when the order replace has been rejected

=item C<order_cancel_rejected> - Sent when the order cancel has been rejected

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
