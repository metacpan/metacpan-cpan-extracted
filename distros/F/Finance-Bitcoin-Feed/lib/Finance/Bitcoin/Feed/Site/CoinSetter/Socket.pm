package Finance::Bitcoin::Feed::Site::CoinSetter::Socket;
use JSON;
use Scalar::Util qw(weaken);

use Mojo::Base 'Mojo::Transaction::WebSocket';

has 'owner';

sub configure {
    my $self  = shift;
    my $owner = shift;
    $self->owner($owner);
    weaken($self->{owner});

    # call parse when receive text event
    $self->on(
        text => sub {
            my ($self, $message) = @_;
            $self->parse($message);
        });

    ################################################
    # setup events
    $self->on(
        subscribe => sub {
            my ($self, $channel) = @_;
            $self->on(
                'setup',
                sub {
                    $self->send({text => qq(5:::{"name":"$channel","args":[""]})});
                });
        });
    $self->emit('subscribe', 'last room');
    $self->on(
        last => sub {
            my ($self, $data) = @_;
            $self->owner->emit('data_out', $data->[0]{'timeStamp'}, 'BTCUSD', $data->[0]{price});
        });
    return;
}

#socketio v0.9.6
sub parse {

    my ($tx, $data) = @_;

    my @packets = ('disconnect', 'connect', 'heartbeat', 'message', 'json', 'event', 'ack', 'error', 'noop');

    my $regexp = qr/([^:]+):([0-9]+)?(\+)?:([^:]+)?:?([\s\S]*)?/;

    my @pieces = $data =~ $regexp;
    return {} unless @pieces;
    my $id = $pieces[1] || '';
    $data = $pieces[4] || '';
    my $packet = {
        type     => $packets[$pieces[0]],
        endpoint => $pieces[3] || '',
    };

    # whether we need to acknowledge the packet
    if ($id) {
        $packet->{id} = $id;
        if ($pieces[3]) {
            $packet->{ack} = 'data';
        } else {
            $packet->{ack} = 'true';
        }

    }

    # handle different packet types
    if ($packet->{type} eq 'error') {

        # need do nothing now.
    } elsif ($packet->{type} eq 'message') {
        $packet->{data} = $data || '';
    }

#"5:::{"name":"last","args":[{"price":367,"size":0.03,"exchangeId":"COINSETTER","timeStamp":1417382915802,"tickId":14667678802537,"volume":14.86,"volume24":102.43}]}"
    elsif ($packet->{type} eq 'event') {
        eval {
            my $opts = decode_json($data);
            $packet->{name} = $opts->{name};
            $packet->{args} = $opts->{args};
        } || 0;    # add '|| 0' to avoid critic test failed
        $packet->{args} ||= [];

        $tx->emit($packet->{name}, $packet->{args});
    } elsif ($packet->{type} eq 'json') {
        evel {
            $packet->{data} = decode_json($data);
        }
    } elsif ($packet->{type} eq 'connect') {
        $packet->{qs} = $data || '';
        $tx->emit('setup');
    } elsif ($packet->{type} eq 'ack') {

        # nothing to do now
        # because this site seems don't emit this packet.
    } elsif ($packet->{type} eq 'heartbeat') {

        #send back the heartbeat
        $tx->send({text => qq(2:::)});
    } elsif ($packet->{type} eq 'disconnect') {
        $tx->owner->debug('disconnected by server');
        $tx->owner->set_timeout();
    }
    return;
}

1;
