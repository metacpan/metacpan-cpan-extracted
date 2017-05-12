package Finance::Bitcoin::Feed::Site::BtcChina::Socket;

use JSON;
use Mojo::Base 'Mojo::Transaction::WebSocket';
use Scalar::Util qw(weaken);
has 'owner';
has 'ping_interval';
has 'ping_timeout';
has 'last_ping_at';
has 'last_pong_at';
has 'timer';

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
                    $self->send({text => qq(42["subscribe","$channel"])});
                });
        });
    $self->emit('subscribe', 'marketdata_cnybtc');
    $self->emit('subscribe', 'marketdata_cnyltc');
    $self->emit('subscribe', 'marketdata_btcltc');

    #receive trade vent
    $self->on(
        trade => sub {
            my ($self, $data) = @_;
            $self->owner->emit(
                'data_out',
                $data->{date} * 1000,    # the unit of timestamp is ms
                uc($data->{market}),
                $data->{price});

        });

    $self->on(
        'ping',
        sub {
            $self->send({text => '2'});
        });

    # ping ping!
    my $timer = AnyEvent->timer(
        after    => 10,
        interval => 1,
        cb       => sub {
            if (time() - $self->last_ping_at > $self->ping_interval / 1000) {
                $self->emit('ping');
                $self->last_ping_at(time());
            }
        });
    $self->timer($timer);
    return;
}

#socket.io v2.2.2
sub parse {
    my ($self, $data) = @_;
    $self->owner->last_activity_at(time());
    return unless $data =~ /^\d+/;
    my ($code, $body) = $data =~ /^(\d+)(.*)$/;

    # connect, setup
    if ($code == 0) {
        my $json_data = decode_json($body);

        #session_id useless ?

        $self->ping_interval($json_data->{pingInterval})
            if $json_data->{pingInterval};
        $self->ping_timeout($json_data->{pingTimeout})
            if $json_data->{pingTimeout};
        $self->last_pong_at(time());
        $self->last_ping_at(time());
        $self->emit('setup');
    }

    # pong
    elsif ($code == 3) {
        $self->last_pong_at(time());
    }

    #disconnect ? reconnect!
    elsif ($code == 41) {
        $self->owner->debug('disconnected by server');

        #set timeout
        $self->owner->set_timeout();
    } elsif ($code == 42) {
        my $json_data = decode_json($body);
        $self->emit($json_data->[0], $json_data->[1]);
    }
    return;
}

1;
