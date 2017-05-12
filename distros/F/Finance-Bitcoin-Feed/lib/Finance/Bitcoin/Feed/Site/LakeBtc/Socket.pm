package Finance::Bitcoin::Feed::Site::LakeBtc::Socket;

use JSON;
use Mojo::Base 'Mojo::Transaction::WebSocket';
use Scalar::Util qw(weaken);
has 'owner';

sub configure {
    my $self  = shift;
    my $owner = shift;
    $self->owner($owner);
    weaken($self->{owner});

    # call parse when receive text event
    $self->on(
        json => sub {
            my ($self, $message) = @_;
            $message = $message->[0];
            my $command = shift @$message;
            $self->emit($command, $message);
        });

    ################################################
    # setup events
    $self->on(
        subscribe => sub {
            my ($self, $channel) = @_;
            $self->on(
                'setup',
                sub {
                    $self->send({json => ['websocket_rails.subscribe', {data => {channel => $channel}}]});
                });
        });
    $self->emit('subscribe', 'ticker');

    ########################################
    # events from server
    $self->on(
        'client_connected',
        sub {
            my $self = shift;
            $self->emit('setup');
        });

    $self->on(
        'websocket_rails.ping',
        sub {
            shift->send({json => ['websocket_rails.pong', undef, undef]});
        });

    $self->on(
        'update',
        sub {
            my ($self, $data) = @_;
            $data = $data->[0]{data};
            for my $k (sort keys %$data) {
                $self->owner->emit(
                    'data_out',
                    0,    # no timestamp
                    uc("${k}BTC"),
                    $data->{$k}{last},
                );
            }

        });
    return;
}

1;
