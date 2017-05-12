package Finance::Bitcoin::Feed::Site::BitStamp::Socket;

use strict;
use warnings;
use parent qw(Finance::Bitcoin::Feed::Pusher);
use Scalar::Util qw(weaken);

sub new {
    my $self = shift->SUPER::new(channels => [qw/live_trades/]);
    $self->{owner} = shift;

    #weaken it to prevent from crossing reference
    weaken($self->{owner});
    return $self;
}

sub trade {
    my $self = shift;
    my $data = shift;
    $self->{owner}->emit('data_out', 0, "BTCUSD", $data->{price});
    return;
}

sub go {
    my $self = shift;
    $self->setup;
    $self->handle;
    return;
}

1;
