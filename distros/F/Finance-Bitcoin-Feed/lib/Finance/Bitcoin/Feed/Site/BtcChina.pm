package Finance::Bitcoin::Feed::Site::BtcChina;
use strict;
use Finance::Bitcoin::Feed::Site::BtcChina::Socket;
use Mojo::Base 'Finance::Bitcoin::Feed::Site';
use Mojo::UserAgent;

our $VERSION = '0.05';

has ws_url => 'wss://websocket.btcchina.com/socket.io/?transport=websocket';
has 'ua';
has 'site' => 'BTCCHINA';

sub go {
    my $self = shift;
    $self->SUPER::go;

    $self->ua(Mojo::UserAgent->new());
    $self->debug('connecting...', $self->ws_url);
    $self->ua->websocket(
        $self->ws_url => sub {
            my ($ua, $tx) = @_;
            $self->debug('connected!');
            unless ($tx->is_websocket) {
                $self->error("Site BtcChina WebSocket handshake failed!");

                # set timeout;
                $self->set_timeout;
                return;
            }

            bless $tx, 'Finance::Bitcoin::Feed::Site::BtcChina::Socket';
            $tx->configure($self);
        });
    return;
}

1;
__END__

=head1 NAME

Finance::Bitcoin::Feed::Site::BtcChina -- the class that connect and fetch the bitcoin price data from site btcchina

=head1 SYNOPSIS

    use Finance::Bitcoin::Feed::Site::BtcChina;
    use AnyEvent;

    my $obj = Finance::Bitcoin::Feed::Site::BtcChina->new();
    # listen on the event 'output' to get the adata
    $obj->on('output', sub { shift; say @_ });
    $obj->go();

    # dont forget this
    AnyEvent->condvar->recv;

=head1 DESCRIPTION

Connect to site BitStamp by protocol socket.io v2.2.2 and fetch the bitcoin price data.

=head1 EVENTS

This class inherits all events from L<Finance::Bitcoin::Feed::Site> and add some new ones.
The most important event is 'output'.

=head2 output

It will be emit by its parent class when print out the data. You can listen on this event to get the output.

=head2 subscribe

It will subscribe channel from the source site. You can subscribe more channels in the method L</configure>

=head1 SEE ALSO

L<Finance::Bitcoin::Feed::Site>

L<btcchina api|http://btcchina.org/websocket-api-market-data-documentation-en>

L<socket.io-parse|https://github.com/Automattic/socket.io-parser>

L<Mojo::UserAgent>

=head1 AUTHOR

Chylli  C<< <chylli@binary.com> >>

