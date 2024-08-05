#!/usr/bin/env perl
# ABSTRACT: Embedding examples

$|=1;

use utf8;
use open ':std', ':encoding(UTF-8)';
use strict;
use warnings;
use Data::Dumper;

use Langertha::Engine::Ollama;
use Langertha::Engine::OpenAI;

my @names_list = qw(
  Harley Ramirez
  David Lin
  Makenna Dominguez
  Kaden Chen
  Valeria McKinney
  Romeo Perry
  Clara Brewer
  Cruz Gillespie
  Alianna Stevens
  Zachary Velez
  Megan Dougherty
  Brett Villanueva
  Monroe Carlson
  Paul Brooks
  Autumn Berry
  Adonis Yates
  Charley Bowman
  Francisco McConnell
  Denise Potter
);
my @names;
while (@names_list) {
  push @names, join(' ', shift @names_list, shift @names_list);
}

{
  if ($ENV{OLLAMA_URL}) {
    my $start = time;

    my $ollama = Langertha::Engine::Ollama->new(
      url => $ENV{OLLAMA_URL},
    );

    for my $name (@names) {
      print ".";
      $ollama->simple_embedding($name);
    }

    my $end = time;
    printf("\n\n%u\n\n", $end - $start);
  }
}

{
  if ($ENV{OPENAI_API_KEY}) {
    my $start = time;

    my $openai = Langertha::Engine::OpenAI->new(
      api_key => $ENV{OPENAI_API_KEY},
    );

    for my $name (@names) {
      print ".";
      $openai->simple_embedding($name);
    }

    my $end = time;
    printf("\n\n%u\n\n", $end - $start);
  }
}

exit 0;