#!/usr/bin/env perl
# ABSTRACT: OpenAI/Ollama Structured Output

$|=1;

use FindBin;
use lib "$FindBin::Bin/../lib";

use utf8;
use open ':std', ':encoding(UTF-8)';
use strict;
use warnings;
use Data::Dumper;
use JSON::MaybeXS;
use Carp qw( croak );
use DDP;

use Langertha::Engine::Ollama;
use Langertha::Engine::OpenAI;

my $jsonschema = {
  type => 'object',
  properties => {
    activities => {
      type => 'array',
      items => {
        type => 'object',
        properties => {
          time => {
            type => 'integer',
            #description => 'Time in minutes',
          },
          action => {
            type => 'string',
            #description => 'Action to be done',
          },
        },
        required => ['time','action'],
        additionalProperties => JSON->false,
      },
    },
  },
  required => [qw( activities )],
  additionalProperties => JSON->false,
};

my $prompt = <<"__EOP__";

I want to improve my cardio fitness. Help me set up a training plan. I enjoy running and occasionally cycling.
I am a beginner and have about 60 minutes three times a week.

__EOP__

{
  if ($ENV{OLLAMA_URL}) {

    my $model = $ENV{OLLAMA_MODEL} || 'llama3.1:8b';

    my $ollama = Langertha::Engine::Ollama->new(
      model => $ENV{OLLAMA_MODEL},
      url => $ENV{OLLAMA_URL},
    );

    if ($ENV{TEST_WITHOUT_STRUCTURED_OUTPUT}) {
      my $start = time;

      my $nostructresult = $ollama->simple_chat($prompt);

      print Dumper $nostructresult;

      my $end = time;
      printf("\n\n%u\n\n", $end - $start);
    }

    my $structured = $ollama->openai( response_format => {
      type => "json_schema",
      json_schema => {
        name => "training",
        schema => $jsonschema,
        strict => JSON->true,
      },
    });

    my $structstart = time;

    my $result = $structured->simple_chat($prompt.' Respond in JSON.');

    my $structend = time;

    eval {
      my $res = JSON::MaybeXS->new->utf8->decode($result);
      print Dumper $res;
    };
    if ($@) {
      print Dumper $result;
    }

    printf("\n\n%u\n\n", $structend - $structstart);
  }
}

exit 0;