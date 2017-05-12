package Finance::Bitcoin::Feed::Site::CoinSetter;
use strict;
use Finance::Bitcoin::Feed::Site::CoinSetter::Socket;
use Mojo::Base 'Finance::Bitcoin::Feed::Site';
use Mojo::UserAgent;

our $VERSION = '0.05';

# Module implementation here
has ws_url => 'https://plug.coinsetter.com:3000/socket.io/1';
has 'ua';
has 'site' => 'COINSETTER';

# this site need 2 handshakes
# 1. get session id by http GET method
# 2. generate a new url by adding session id to the old url
# 3. connect by socket id
sub go {
    my $self = shift;
    $self->SUPER::go;
    $self->ua(Mojo::UserAgent->new());
    $self->debug('get handshake information');
    my $tx = $self->ua->get($self->ws_url);
    unless ($tx->success) {
        my $err = $tx->error;
        $self->error("Connection error of Site CoinSetter: $err->{message}");
        $self->set_timeout;
        return;
    }

    # f_P7lQkhkg4JD5Xq0LCl:60:60:websocket,htmlfile,xhr-polling,jsonp-polling
    my ($sid, $hb_timeout, $con_timeout, $transports) = split /:/, $tx->res->text;

    my $url = $self->ws_url . "/websocket/$sid";
    $url =~ s/https/wss/;

    $self->debug('connecting...', $url);

    my $socket = $self->ua->websocket(
        $url => sub {
            my ($ua, $tx) = @_;
            $self->debug('connected!');
            unless ($tx->is_websocket) {
                $self->error("Site BtcChina WebSocket handshake failed!");

                # set timeout;
                $self->set_timeout;
                return;
            }
            bless $tx, 'Finance::Bitcoin::Feed::Site::CoinSetter::Socket';
            $tx->configure($self);
        });
    return;
}

1;

__END__

=head1 NAME

Finance::Bitcoin::Feed::Site::CoinSetter -- the class that connect and fetch the bitcoin price data from site Coinsetter


=head1 SYNOPSIS

    use Finance::Bitcoin::Feed::Site::CoinSetter;
    use AnyEvent;

    my $obj = Finance::Bitcoin::Feed::Site::BitStamp->new();
    # listen on the event 'output' to get the adata
    $obj->on('output', sub { shift; say @_ });
    $obj->go();

    # dont forget this 
    AnyEvent->condvar->recv;
  
=head1 DESCRIPTION

Connect to site BitStamp by protocol socket.io v 0.9.6 and fetch the bitcoin price data.

=head1 EVENTS

This class inherits all events from L<Finance::Bitcoin::Feed::Site> and add some new ones.
The most important event is 'output'.

=head2 output

It will be emit by its parent class when print out the data. You can listen on this event to get the output.

=head2 subscribe

It will subscribe channel from the source site. You can subscribe more channels in the method L</configure>

=head1 SEE ALSO

L<Finance::Bitcoin::Feed::Site>

L<https://www.coinsetter.com/api>

L<Mojo::UserAgent>

L<socket.io-parser|https://github.com/Automattic/socket.io-parser>

=head1 AUTHOR

Chylli  C<< <chylli@binary.com> >>

