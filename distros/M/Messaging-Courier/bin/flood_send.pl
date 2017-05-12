use lib './lib';
use strict;
use warnings;

use Messaging::Courier;
use Messaging::Courier::ChatMessage;

my $c = Messaging::Courier->new();

my $mailbox = $c->mailbox;

my $i = 1;

while (1) {
  my $m = Messaging::Courier::ChatMessage->new();
  $m->text($i++);
  $m->nick('flood_client');
  $c->send($m);

  if (($i % 100) == 0) {
    print "$i...\n";
    $c->reconnect;
  }
}
