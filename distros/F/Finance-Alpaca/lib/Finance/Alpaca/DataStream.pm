package Finance::Alpaca::DataStream 0.9904 {
    use strictures 2;
    use Moo;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    use Types::Standard qw[ArrayRef CodeRef Dict Enum InstanceOf Str];
    use Mojo::Promise;
    #
    use lib './lib/';
    use Finance::Alpaca::Struct::Bar qw[to_Bar Bar];
    use Finance::Alpaca::Struct::Trade qw[to_Trade Trade];
    use Finance::Alpaca::Struct::Quote qw[to_Quote Quote];
    #
    has source => ( is => 'ro', isa => Enum [ 'iex', 'sip' ], required => 1, default => 'iex' );
    has tx => ( is => 'rwp', isa => InstanceOf ['Mojo::Transaction::WebSocket'], predicate => 1 );
    has cb => ( is => 'ro',  isa => CodeRef, required => 1 );
    has subscriptions => (
        is  => 'rwp',
        isa => Dict [
            bars   => ArrayRef [Str], dailyBars => ArrayRef [Str], quotes => ArrayRef [Str],
            trades => ArrayRef [Str]
        ],
        default => sub { { bars => [], quotes => [], trades => [] } },
        lazy    => 1
    );

    sub authorize ( $s, $ua, $keys ) {
        $ua->websocket_p( 'wss://stream.data.alpaca.markets/v2/'
                . $s->source => { 'Sec-WebSocket-Extensions' => 'permessage-deflate' } )->then(
            sub ($tx) {
                my $promise = Mojo::Promise->new;
                $s->_set_tx($tx);

                #$tx->on( finish => sub { $promise->resolve } );
                # my $promise = Mojo::Promise->new;
                #$tx->on( finish => sub { $promise->resolve } );
                $tx->on(
                    json => sub ( $tx, $msgs ) {
                        for my $msg (@$msgs) {

                            if ( $msg->{T} eq 'success' ) {
                                if ( $msg->{msg} eq 'connected' ) {    # Send auth
                                    $tx->send(
                                        {
                                            json => {
                                                action => 'auth',
                                                key    => $keys->[0],
                                                secret => $keys->[1]
                                            }
                                        }
                                    );
                                }
                                elsif ( $msg->{msg} eq 'authenticated' ) {
                                    $promise->resolve;
                                }
                            }
                            elsif ( $msg->{T} eq 'error' ) {
                                $s->cb->($msg);
                                if ( $msg->{code} eq 406 ) {    # Already connected; ignore

                                    # Send auth
                                    $tx->send(
                                        {
                                            json => {
                                                action => 'auth',
                                                key    => $s->keys->[0],
                                                secret => $s->keys->[1]
                                            }
                                        }
                                    );
                                }
                            }
                            elsif ( $msg->{T} eq 't' ) {
                                $s->cb->( to_Trade($msg) );
                            }
                            elsif ( $msg->{T} eq 'q' ) {
                                $s->cb->( to_Quote($msg) );
                            }
                            elsif ( $msg->{T} eq 'b' ) {
                                $s->cb->( to_Bar($msg) );
                            }
                            elsif ( $msg->{T} eq 'subscription' ) {
                                delete $msg->{T};
                                $s->_set_subscriptions($msg);
                            }
                            else {
                                #warn 'unknown data';
                                #...;
                                $s->cb->($msg);
                            }
                        }

                        #$tx->finish;
                    }
                );
                return $promise;
            }
        )->catch(
            sub ($err) {
                warn "WebSocket error: $err";
            }
        );
    }

    sub subscribe ( $s, %params ) {
        $s->tx->send( { json => { action => 'subscribe', %params } } );
    }

    sub unsubscribe ( $s, %params ) {
        $s->tx->send( { json => { action => 'unsubscribe', %params } } );
    }
}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::DataStream - A Streaming, Real-time Data Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    my $stream = Finance::Alpaca->new( ... )->data_stream(
        sub ($packet) { ...; }
    );
    $stream->subscribe(
        quotes => ['MSFT'], trades => ['MSFT'], bars => ['*']
    );
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

=head1 DESCRIPTION

Finance::Alpaca::DataStream receives real-time market data.

You can send one or more subscription messages (described below) and after
confirmation you will receive the corresponding market data.

At any time you can subscribe to or unsubscribe from symbols. Please note that
due to the internal buffering mentioned above for a short while you may receive
data points for symbols you have recently unsubscribed from.

=head1 METHODS

=head2 C<subscribe( ... )>

    $stream->subscribe(
        quotes => ['MSFT'], trades => ['MSFT'], bars => ['*']
    );

You can subscribe to C<trades>, C<quotes> and C<bars> of a particular symbol
(or C<*> for every symbol in the case of bars). A subscribe message should
contain what subscription you want to add to your current subscriptions in your
session so you don’t have to send what you’re already subscribed to.

This method accepts the following parameters:

=over

=item C<bars> - List of ticker symbols

=item C<dailyBars> - List of ticker symbols

=item C<quotes> - List of ticker symbols

=item C<trades> - List of ticker symbols or C<*>

=back

You can also omit either one of them (C<trades>, C<quotes>, or C<bars>) if you
don’t want to subscribe to any symbols in that category but be sure to
include at least one of the three.

=head2 C<subscriptions( )>

    my $current = $stream->subscriptions( );

After subscribing or unsubscribing, our websocket will receive a message that
describes your current list of subscriptions. You may access this data with
this method.

=head2 C<unsubscribe( ... )>

    $stream->unsubscribe(
        quotes => ['MSFT']
    );

Much like subscribe you can also send an unsubscribe message that subtracts the
list of subscriptions specified from your current set of subscriptions.

This method accepts the following parameters:

=over

=item C<bars> - List of ticker symbols

=item C<quotes> - List of ticker symbols

=item C<trades> - List of ticker symbols or C<*>

=back

You can also omit either one of them (C<trades>, C<quotes>, or C<bars>) if you
don’t want to subscribe to any symbols in that category but be sure to
include at least one of the three.

=head1 Errors

Unhandled errors are passed directly to the callback. Possible errors
include...

=over

=item C<400>

    { T => 'error', code => 400, msg => 'invalid syntax' }

The message you sent to the server did not follow the specification.

=item C<401>

    { T => 'error', code => 401, msg => 'not authenticated' }

You have attempted to subscribe or unsubscribe before authentication.

=item C<402>

    { T => 'error', code => 402, msg => 'auth failed' }

You have provided invalid authentication credentials.

=item C<403>

    { T => 'error', code => 403, msg => 'already authenticated' }

You have already successfully authenticated during your current session.

=item C<404>

    { T => 'error', code => 404, msg => 'auth timeout' }

You failed to successfully authenticate after connecting. You have a few
seconds to authenticate after connecting.

=item C<405>

    { T => 'error', code => 405, msg => 'symbol limit exceeded' }

The symbol subscription request you sent would put you over the limit set by
your subscription package. If this happens your symbol subscriptions are the
same as they were before you sent the request that failed.

=item C<406>

    { T => 'error', code => 406, msg => 'connection limit exceeded' }

You already have an ongoing authenticated session.

=item C<407>

    { T => 'error', code => 407, msg => 'slow client' }

You may receive this if you are too slow to process the messages sent by the
server. Please note that this is not guaranteed to arrive before you are
disconnected to avoid keeping slow connections active forever.

=item C<408>

    { T => 'error', code => 408, msg => 'v2 not enabled' }

Your account does not have access to Data v2.

=item C<409>

    { T => 'error', code => 409, msg => 'insufficient subscription' }

You have attempted to access a data source not available in your subscription
package.

=item C<500>

    { T => 'error', code => 500, msg => 'internal error' }

An unexpected error occurred on our end and Alpaca is investigating the issue.

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords unsubscribe unsubscribing unsubscribed websocket

=cut
# https://alpaca.markets/docs/api-documentation/api-v2/market-data/alpaca-data-api-v2/real-time/
