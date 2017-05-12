package Minion::Notifier::Transport::Redis;

use Mojo::Base 'Minion::Notifier::Transport';

use Mojo::Redis2;
use Mojo::JSON;

has redis => sub { die 'A Mojo::Redis2 instance is required' };

has channel => 'minion_notifier_job';

sub listen {
  my $self = shift;
  my $channel = $self->channel;
  $self->redis->on(message => sub {
    my ($redis, $payload, $c) = @_;
    return unless $c eq $channel;
    my $args = Mojo::JSON::decode_json $payload;
    $self->emit(notified => @$args);
  });
  $self->redis->subscribe([$channel], sub {});
}

sub send {
  my ($self, $id, $message) = @_;
  my $payload = Mojo::JSON::encode_json([$id, $message]);
  Mojo::IOLoop->delay(sub{
    $self->redis->publish($self->channel, $payload, shift->begin);
  })->wait;
}

1;

