#!perl

use feature 'say';
use common::sense;
use Ion;

my $client = Connect localhost => 4242;

sub put {
  $client->("put $_[0]");
  return <$client> eq 'ok';
}

sub get {
  $client->("get");
  my $line = <$client>;
  return if $line eq 'empty';
  return $line;
}

sub size {
  $client->("size");
  <$client>;
}


my $count = shift @ARGV || 10;

for (1 .. $count) {
  if (put $_) {
    say "put $_: ", size, ' in the queue';
  }
  else {
    say ':(';
  }
}

while (my $n = get) {
  say "got $n: ", size, ' in the queue';
}
