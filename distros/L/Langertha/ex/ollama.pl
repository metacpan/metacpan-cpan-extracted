#!/usr/bin/env perl
# ABSTRACT: Embedding examples

$|=1;

use utf8;
use open ':std', ':encoding(UTF-8)';
use strict;
use warnings;
use Data::Dumper;

use Langertha::Engine::Ollama;

{
  if ($ENV{OLLAMA_URL}) {
    my $start = time;

    my $ollama = Langertha::Engine::Ollama->new(
      url => $ENV{OLLAMA_URL},
    );

    my $tags = $ollama->simple_tags;

    my $end = time;
    printf("\n\n%u\n\n", $end - $start);
  }
}

exit 0;