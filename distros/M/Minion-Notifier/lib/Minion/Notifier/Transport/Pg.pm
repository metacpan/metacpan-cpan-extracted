package Minion::Notifier::Transport::Pg;

use Mojo::Base 'Minion::Notifier::Transport';

use Mojo::Pg;
use Mojo::JSON;

has pg => sub { die 'A Mojo::Pg instance is required' };

has channel => 'minion_notifier_job';

sub listen {
  my $self = shift;
  $self->pg->pubsub->listen($self->channel => sub {
    my ($pubsub, $payload) = @_;
    my $args = Mojo::JSON::decode_json $payload;
    $self->emit(notified => @$args);
  });
}

sub send {
  my ($self, $id, $message) = @_;
  $self->pg->pubsub->notify(
    $self->channel,
    Mojo::JSON::encode_json([$id, $message]),
  );
}

sub _start {
  my $self = shift;
  # The pubsub object needs to be refreshed.
  # Currently this is the best way to do that.
  $self->pg->pubsub->unlisten($self->channel . '_dummy');
}

1;

