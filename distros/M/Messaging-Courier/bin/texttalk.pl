use lib './lib';

use strict;
use warnings;

use Messaging::Courier;
use Messaging::Courier::ChatMessage;
use Term::ReadKey;

my $c = Messaging::Courier->new();

while (1) {
  my $text = ReadLine -1, *STDIN;
  if ($text) {
    chomp $text;
    my $m = Messaging::Courier::ChatMessage->new();
    $m->text($text);
    $c->send($m);
  }
  my $m = $c->receive(0.1);
  if (UNIVERSAL::isa($m, 'Messaging::Courier::ChatMessage') && $m->nick ne $ENV{USER}) {
    print $m->nick . ": " . $m->text . "\n";
  }
}

