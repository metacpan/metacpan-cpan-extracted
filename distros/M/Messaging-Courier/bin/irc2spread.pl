package IRC2Spread;
use lib './lib';
use strict;
use warnings;
use Messaging::Courier;
use Messaging::Courier::ChatMessage;
use base qw(Bot::BasicBot);

my $courier;

sub init {
  my ($self) = shift;
  $courier = Messaging::Courier->new();
  return $self;
}

sub said {
  my($self, $args) = @_;
  my $who = $args->{who};
  my $body = $args->{body};

  my $m = Messaging::Courier::ChatMessage->new();
  $m->nick($who);
  $m->text($body);
  $courier->send($m);
}

sub tick {
  my($self, $args) = @_;

  my $m = $courier->receive(0.1);

  if (UNIVERSAL::isa($m, 'Messaging::Courier::ChatMessage')) {
    my $senderid = $m->frame->sender;
    my $myid = $courier->id;
    if ($senderid ne $myid) {
      $self->say(
        channel => '#fotango',
        body    => '<' . $m->nick . "> " . $m->text,
      );
    }
  }

  return 1;
}

package main;

# with all known options
IRC2Spread->new(
  channels => ["#courier"],
  server => "geekflat.org",
  port   => "6667",

  nick      => "irc2spread",
  username  => "bot",
  name      => "Transports IRC to Spread",
#  ignore_list => [qw(dipsy dadadodo laotse)],
)->init()->run();
