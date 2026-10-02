#!/usr/bin/env perl
# ABSTRACT: Ollama keep_alive: bare numbers go out as JSON numbers, durations as strings
use strict;
use warnings;
use Test2::Bundle::More;

use JSON::MaybeXS;
use Langertha::Engine::Ollama;

# karr k333: Ollama's api.Duration.UnmarshalJSON (api/types.go) takes a JSON
# number as seconds (negative = keep forever) but runs time.ParseDuration on a
# JSON string, which rejects a unit-less "-1" or "300" ("missing unit in
# duration"). So the documented keep_alive => '-1' made every chat request
# fail. A plain number must reach the wire as a JSON number; a duration with a
# unit stays a string. Asserted on the raw JSON text, where the type shows.

sub raw_keep_alive {
  my ( %args ) = @_;
  my $e = Langertha::Engine::Ollama->new( url => 'http://h:11434', model => 'm', %args );
  my @raw;
  for my $req ( $e->chat('hi'), $e->chat_stream_request( $e->chat_messages('hi') ) ) {
    my ($raw) = $req->content =~ /"keep_alive":("[^"]*"|[^,}]+)/;
    push @raw, $raw;
  }
  return @raw;
}

for my $case (
  [ '-1'  => '-1' ],
  [ -1    => '-1' ],
  [ '300' => '300' ],
  [ '0'   => '0' ],
  [ '1.5' => '1.5' ],
  [ '5m'  => '"5m"' ],
  [ '1h'  => '"1h"' ],
  [ '-1m' => '"-1m"' ],
) {
  my ( $in, $want ) = @$case;
  my ( $chat, $stream ) = raw_keep_alive( keep_alive => $in );
  is $chat,   $want, "keep_alive => '$in' goes out as $want (chat)";
  is $stream, $want, "keep_alive => '$in' goes out as $want (stream)";
}

{
  my ( $chat, $stream ) = raw_keep_alive( no_keep_alive => 1, keep_alive => '5m' );
  is $chat,   '0', 'no_keep_alive sends the number 0 (chat)';
  is $stream, '0', 'no_keep_alive sends the number 0 (stream)';
}

{
  my ( $chat ) = raw_keep_alive();
  is $chat, undef, 'no keep_alive set: the field is absent';
}

done_testing;
