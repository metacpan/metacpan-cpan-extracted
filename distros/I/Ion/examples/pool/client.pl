#!perl

use feature 'say';
use common::sense;
use Data::Dump::Streamer;
use MIME::Base64 qw(encode_base64 decode_base64);
use Ion;

sub work {
  my $n = shift;
  return $n * 2;
}

my $count = shift @ARGV || 10;

my $client = Connect localhost => 4242;

$client
  << sub{ decode_base64($_[0]) }
  << sub{ my $msg = eval $_[0]; $@ && die $@; $msg };

$client
  >> sub{ Dump(shift)->Purity(1)->Declare(1)->Indent(0)->Out }
  >> sub{ encode_base64($_[0], '') };

foreach my $i (1 .. $count) {
  $client->([\&work, $i]);
  my $result = <$client>;
  say $i, ' * 2 = ', $result;
}
