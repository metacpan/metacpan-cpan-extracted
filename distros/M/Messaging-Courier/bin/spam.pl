use lib './lib';

use strict;
use warnings;

use Messaging::Courier;
use Messaging::Courier::ChatMessage;
use Term::ReadKey;

my $c = Messaging::Courier->new();

while(<>){
  my $m = Messaging::Courier::ChatMessage->new();
  $m->text($_);
  $m->nick('spam');
  $c->send($m);
}
