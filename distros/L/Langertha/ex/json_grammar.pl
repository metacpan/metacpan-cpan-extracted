#!/usr/bin/env perl
# ABSTRACT: JSON grammar test

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

use Langertha::Engine::Ollama;

croak "Requires OLLAMA_URL" unless $ENV{OLLAMA_URL};

my $model = $ENV{OLLAMA_MODEL} || 'gemma2:2b';

my $jsonschema = <<'__EOS__';

{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "type": "object",
  "properties": {
    "activities": {
      "type": "array",
      "items": [
        {
          "type": "object",
          "properties": {
            "time": {
              "type": "integer",
              "description": "Time in minutes"
            },
            "action": {
              "type": "string",
              "description": "Action to be done"
            }
          },
          "required": [
            "time",
            "action"
          ]
        },
        {
          "type": "object",
          "properties": {
            "time": {
              "type": "integer"
            },
            "action": {
              "type": "string"
            }
          },
          "required": [
            "time",
            "action"
          ]
        }
      ]
    }
  },
  "required": [
    "activities"
  ]
}

__EOS__

my $jprompt = <<"__EOP__";

You are an assistant that only speaks JSON, and your JSON always follows this specific JSON Schema:

$jsonschema

__EOP__

{
  my $start = time;

  my $ollamajson = Langertha::Engine::Ollama->new(
    url => $ENV{OLLAMA_URL},
    json_format => 1,
    system_prompt => $jprompt,
  );

  my $prompt = <<"__EOP__";

I want to improve my cardio fitness. Help me set up a training plan. I enjoy running and occasionally cycling. I am a beginner and have about 60 minutes three times a week.

Please reply as JSON strictly following this JSON Schema:

$jsonschema

__EOP__

  my $result = $ollamajson->simple_chat($prompt);

  eval {
    my $data = decode_json($result);
    print Dumper($data);
  };
  if ($@) {
    print STDERR "\n".$@."\n";
    print Dumper($result);
  }

  my $end = time;
  printf("\n -- %u seconds\n", ($end - $start));
}

{
  my $start = time;

  my $ollama = Langertha::Engine::Ollama->new(
    url => $ENV{OLLAMA_URL},
  );

  my $prompt = <<"__EOP__";

I want to improve my cardio fitness. Help me set up a training plan. I enjoy running and occasionally cycling. I am a beginner and have about 60 minutes three times a week.

__EOP__

  my $reply = $ollama->simple_chat($prompt);

  print "\n\n".$reply."\n\n";

  my $middle = time;
  printf("\n\n --------------------- %u ----------------------- \n\n", $middle - $start);

  my $ollamajson = Langertha::Engine::Ollama->new(
    url => $ENV{OLLAMA_URL},
    json_format => 1,
    system_prompt => $jprompt,
  );

  my $result = $ollamajson->simple_chat($reply);

  eval {
    my $data = decode_json($result);
    print Dumper($data);
  };
  if ($@) {
    print STDERR "\n".$@."\n";
    print Dumper($result);
  }

  my $end = time;
  printf("\n -- %u seconds\n", ($end - $start));
}

exit 0;