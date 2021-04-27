package Finance::Alpaca::TradeStream 0.9900 {
    use strictures 2;
    use Moo;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    use Types::Standard qw[ArrayRef CodeRef Dict Enum InstanceOf Str];
    use Mojo::Promise;
    #
    use lib './lib/';
    use Finance::Alpaca::Struct::TradeUpdate qw[to_TradeUpdate];
    #
    has tx => ( is => 'rwp', isa => InstanceOf ['Mojo::Transaction::WebSocket'], predicate => 1 );
    has cb => ( is => 'ro',  isa => CodeRef, required => 1 );
    has subscriptions => ( is => 'rwp', isa => ArrayRef [Str], default => sub { [] }, lazy => 1 );

    sub authorize ( $s, $ua, $keys, $paper ) {

        #use Data::Dump;
        #ddx $keys;
        $ua->inactivity_timeout(120);    # XXX - Testing!

        # warn(
        #     $paper ? 'wss://paper-api.alpaca.markets/stream' : 'wss://api.alpaca.markets/stream' );
        $ua->websocket_p(
            (
                $paper
                ? 'wss://paper-api.alpaca.markets/stream'
                : 'wss://api.alpaca.markets/stream'
            )
        )->then(
            sub ($tx) {
                my $promise = Mojo::Promise->new;
                $s->_set_tx($tx);

                #$tx->on( finish => sub { $promise->resolve } );
                # my $promise = Mojo::Promise->new;
                #$tx->on( finish => sub { $promise->resolve } );
                $tx->on(
                    finish => sub ( $tx, $code, $reason = '' ) {
                        warn "WebSocket closed with status $code. $reason";
                        $promise->resolve;
                    }
                );
                $tx->on( error => sub ( $e, $err ) { warn "This looks bad: $err" } );
                $tx->on(
                    json => sub ( $tx, $msg = () ) {
                        if ( $msg->{stream} eq 'authorization' ) {
                            if ( $msg->{data}{status} eq 'authorized' ) {
                                $s->subscribe( streams => ['trade_updates'] );
                                $promise->resolve();
                            }
                        }
                        elsif ( $msg->{stream} eq 'listening' ) {
                            $s->_set_subscriptions( $msg->{data}{streams} );
                        }
                        elsif ( $msg->{stream} eq 'trade_updates' ) {
                            $s->cb->( to_TradeUpdate( $msg->{data} ) );
                        }
                        else {
                            #warn 'unknown data';
                            #...;
                            $s->cb->($msg);
                        }

                        #$tx->finish;
                    }
                );
                $tx->send(
                    {
                        json => {
                            action => 'authenticate',
                            data   => { key_id => $keys->[0], secret_key => $keys->[1] }
                        }
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
        $s->tx->send( { json => { action => 'listen', data => {%params} } } );
    }

    sub unsubscribe ( $s, %params ) {    # XXX - Grep current list
        $s->tx->send( { json => { action => 'listen', data => {%params} } } );
    }
}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca::TradeStream - A Streaming, Account and Order Updates Object

=head1 SYNOPSIS

    use Finance::Alpaca;
    my $stream = Finance::Alpaca->new( ... )->trade_stream(
        sub ($packet) { ...; }
    );
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

=head1 DESCRIPTION

Finance::Alpaca::TradeStream receives real-time activity data and passes it on
to your callback as Finance::Alpaca::TradeUpdate objects.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
# https://alpaca.markets/docs/api-documentation/api-v2/market-data/alpaca-data-api-v2/real-time/
