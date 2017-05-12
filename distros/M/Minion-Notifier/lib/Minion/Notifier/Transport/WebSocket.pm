package Minion::Notifier::Transport::WebSocket;

use Mojo::Base 'Minion::Notifier::Transport';

use Mojo::URL;
use Mojo::UserAgent;

has ua => sub { Mojo::UserAgent->new };
has url => sub { die 'url is required' };

sub listen {
  my $self = shift;
  $self->ua->websocket($self->url => sub {
    my ($ua, $tx) = @_;
    $tx->on(json => sub {
      my ($tx, $data) = @_;
      $self->emit(notified => @$data);
    });
  });
}

sub send {
  my ($self, $id, $message) = @_;
  $self->ua->websocket($self->url => sub {
    my ($ua, $tx) = @_;
    $tx->send({json => [$id, $message]}); #TODO finish after send?
  });
}


1;

