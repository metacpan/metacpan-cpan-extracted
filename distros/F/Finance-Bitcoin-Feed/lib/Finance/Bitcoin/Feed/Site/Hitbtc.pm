package Finance::Bitcoin::Feed::Site::Hitbtc;

use strict;
use warnings;
use Mojo::Base 'Finance::Bitcoin::Feed::Site';
use Mojo::UserAgent;

our $VERSION = '0.05';

has ws_url => 'ws://api.hitbtc.com';
has 'ua';
has site => 'HITBTC';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->on('json', \&on_json);

    return $self;
}

sub go {
    my $self = shift;
    $self->SUPER::go(@_);
    $self->ua(Mojo::UserAgent->new);
    $self->debug('connecting...', $self->ws_url);
    $self->ua->websocket(
        $self->ws_url => sub {
            my ($ua, $tx) = @_;
            unless ($tx->is_websocket) {
                $self->error("WebSocket handshake failed!");

                # set timeout;
                $self->set_timeout;
                return;
            }

            $tx->on(
                json => sub {
                    my ($tx, $hash) = @_;
                    $self->emit('json', $hash);
                });
        });
    return;
}

sub on_json {
    my ($self, $hash) = @_;

    if ($hash->{MarketDataIncrementalRefresh}
        && scalar @{$hash->{MarketDataIncrementalRefresh}{trade}})
    {
        for my $trade (@{$hash->{MarketDataIncrementalRefresh}{trade}}) {
            $self->emit('data_out', $trade->{timestamp}, $hash->{MarketDataIncrementalRefresh}{symbol}, $trade->{price});
        }
    }
    return;
}

1;

__END__

=head1 NAME

Finance::Bitcoin::Feed::Site::Hitbtc -- the class that connect and fetch the bitcoin price data from site hitbtc

=head1 SYNOPSIS

    use Finance::Bitcoin::Feed::Site::Hitbtc;
    use AnyEvent;

    my $obj = Finance::Bitcoin::Feed::Site::BtcChina->new();
    # listen on the event 'output' to get the adata
    $obj->on('output', sub { shift; say @_ });
    $obj->go();

    # dont forget this
    AnyEvent->condvar->recv;

=head1 DESCRIPTION

Connect to site Hitbtc by protocol websocket and fetch the bitcoin price data.

=head1 EVENTS

This class inherits all events from L<Finance::Bitcoin::Feed::Site> and add some new ones.
The most important event is 'output'.

=head2 output

It will be emit by its parent class when print out the data. You can listen on this event to get the output.

=head1 SEE ALSO

L<Finance::Bitcoin::Feed::Site>

L<Mojo::UserAgent>

L<hitbtc|https://github.com/hitbtc-com/hitbtc-api>

=head1 AUTHOR

Chylli  C<< <chylli@binary.com> >>

