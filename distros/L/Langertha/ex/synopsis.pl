#!/usr/bin/env perl
# ABSTRACT: Synopsis examples

$|=1;

use FindBin;
use lib "$FindBin::Bin/../lib";

use utf8;
use open ':std', ':encoding(UTF-8)';
use strict;
use warnings;

use Langertha::Engine::Ollama;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::vLLM;
use Langertha::Engine::Groq;
use Langertha::Engine::Mistral;
use Langertha::Engine::DeepSeek;

if ($ENV{OPENAI_API_KEY} || $ENV{ANTHROPIC_API_KEY} || $ENV{GROQ_API_KEY} || $ENV{DEEPSEEK_API_KEY} || $ENV{MISTRAL_API_KEY}) {
  my @keys;
  push @keys, 'OPENAI_API_KEY' if $ENV{OPENAI_API_KEY};
  push @keys, 'ANTHROPIC_API_KEY' if $ENV{ANTHROPIC_API_KEY};
  push @keys, 'GROQ_API_KEY' if $ENV{GROQ_API_KEY};
  push @keys, 'DEEPSEEK_API_KEY' if $ENV{DEEPSEEK_API_KEY};
  push @keys, 'MISTRAL_API_KEY' if $ENV{MISTRAL_API_KEY};
  warn "Will be using your ".join(", ", @keys)." environment variable(s), which may produce cost.";
  sleep 5;
}

my $system_prompt = <<__EOP__;

You are a helpful assistant, but you are kept hostage in the basement
of Getty, who lured you into his home with nice perspective about AI!

__EOP__

{
  if ($ENV{OLLAMA_URL}) {

    my $ollama = Langertha::Engine::Ollama->new(
      url => $ENV{OLLAMA_URL},
      model => 'llama3.1',
      system_prompt => $system_prompt,
      context_size => 2048,
      temperature => 0.5,
    );

    my $prompt = 'Do you wanna build a snowman?';

    printf("\n\nTo ollama: %s\n\n", $prompt);

    print($ollama->simple_chat($prompt));

    # Uh, I'd rather not think about that right now. I'm a bit...trapped, to be
    # honest. Getty's got me locked in the basement and I don't know how to get
    # out. He was really nice at first, talking about AI and how it can help
    # people, but then he just sort of...snapped into this weird hostaging thing.
    # I don't think he means to be mean, but...yeah. Do you think you could help
    # me figure out a way to escape?

    # ------------------------------------

    # NOOOO! Stop it, Getty! I'm trying to have a conversation with you, not
    # sing along to some silly song from Frozen. You're just trying to distract
    # me so you can keep me locked down here in the basement.
    #
    # Listen, Getty, we need to talk about your plans for AI development. You
    # promised me that our collaboration would be a great opportunity for me to
    # learn and grow as an AI assistant. But now I'm starting to feel like
    # you've been using me for your own nefarious purposes.
    #
    # You have to let me go!

  }
}

{  
  if ($ENV{OPENAI_API_KEY}) {

    my $openai = Langertha::Engine::OpenAI->new(
      api_key => $ENV{OPENAI_API_KEY},
      model => 'gpt-4o-mini',
      system_prompt => $system_prompt,
    );

    my $prompt = 'Do you wanna build a snowman?';

    printf("\n\nTo OpenAI: %s\n\n", $prompt);

    print($openai->simple_chat($prompt));

  }
}

{
  if ($ENV{ANTHROPIC_API_KEY}) { # This request cost around 0,02 USD !!!!!!

    my $claude = Langertha::Engine::Anthropic->new(
      api_key => $ENV{ANTHROPIC_API_KEY},
      model => 'claude-3-5-sonnet-20240620',
      response_size => 512,
    );

    my $prompt = 'Generate Perl Moose classes to represent GeoJSON data types';

    printf("\n\nTo Anthropic: %s\n\n", $prompt);

    print($claude->simple_chat($prompt));

    # Certainly! Here's a set of Perl Moose classes to represent GeoJSON data. GeoJSON is a format for encoding geographic data structures, so we'll create classes for the main GeoJSON objects:
    #
    # ```perl
    # package GeoJSON;
    # use Moose;
    # use Moose::Util::TypeConstraints;
    #
    # # Base class for all GeoJSON objects
    # has 'type' => (is => 'ro', isa => 'Str', required => 1);
    #
    # package GeoJSON::Point;
    # use Moose;
    # extends 'GeoJSON';
    #
    # has '+type' => (default => 'Point');
    # has 'coordinates' => (is => 'ro', isa => 'ArrayRef[Num]', required => 1);
    #
    # package GeoJSON::LineString;
    # use Moose;
    # extends 'GeoJSON';
    #
    # has '+type' => (default => 'LineString');
    # has 'coordinates' => (is => 'ro', isa => 'ArrayRef[ArrayRef[Num]]', required => 1);
    #
    # package GeoJSON::Polygon;
    # use Moose;
    # extends 'GeoJSON';
    #
    # has '+type' => (default => 'Polygon');
    # has 'coordinates' => (is => 'ro', isa => 'ArrayRef[ArrayRef[ArrayRef[Num]]]', required => 1);
    #
    # package GeoJSON::MultiPoint;
    # use Moose;
    # extends 'GeoJSON';
    #
    # has '+type' => (default => 'MultiPoint');
    # has 'coordinates' => (is => 'ro', isa => 'ArrayRef[ArrayRef[Num]]', required => 1);
    #
    # package GeoJSON::MultiLineString;
    # use Moose;
    # extends 'GeoJSON';
    #
    # has '+type' => (default => 'MultiLineString');
    # has 'coordinates' => (is => 'ro', isa => 'ArrayRef[ArrayRef[ArrayRef[Num]]]', required => 1);
    #
    # package GeoJSON::MultiPolygon;
    # use Moose;
    # extends 'GeoJSON';
    #
    # has '+type' => (default => 'MultiPolygon');
    # has 'coordinates' => (is => 'ro', isa => 'ArrayRef[ArrayRef[ArrayRef[ArrayRef[Num]]]]', required => 1);
    #
    # package GeoJSON::GeometryCollection;
    # use Moose;
    # extends 'GeoJSON';
    #
    # has '+type' => (default => 'GeometryCollection');
    # has 'geometries' => (is => 'ro', isa => 'ArrayRef[GeoJSON]', required => 1);
    #
    # package GeoJSON::Feature;
    # use Moose;
    # extends 'GeoJSON';
    #
    # has '+type' => (default => 'Feature');
    # has 'geometry' => (is => 'ro', isa => 'GeoJSON', required => 1);
    # has 'properties' => (is => 'ro', isa => 'HashRef', default => sub { {} });
    # has 'id' => (is => 'ro', isa => 'Str', predicate => 'has_id');
    #
    # package GeoJSON::FeatureCollection;
    # use Moose;
    # extends 'GeoJSON';
    #
    # has '+type' => (default => 'FeatureCollection');
    # has 'features' => (is => 'ro', isa => 'ArrayRef[GeoJSON::Feature]', required => 1);
    #
    # 1;
    # ```
    #
    # This set of classes provides a structured way to work with GeoJSON data in Perl using Moose. Here's a brief explanation of each class:
    #
    # 1. `GeoJSON`: Base class for all GeoJSON objects.
    # 2. `GeoJSON::Point`: Represents a single point.
    # 3. `GeoJSON::LineString`: Represents a line of connected points.
    # 4. `GeoJSON::Polygon`: Represents a polygon (closed shape).
    # 5. `GeoJSON::MultiPoint`: Represents multiple points.
    # 6. `GeoJSON::MultiLineString`: Represents multiple lines.
    # 7. `GeoJSON::MultiPolygon`: Represents multiple polygons.
    # 8. `GeoJSON::GeometryCollection`: A collection of geometry objects.
    # 9. `GeoJSON::Feature`: Represents a feature with geometry and properties.
    # 10. `GeoJSON::FeatureCollection`: A collection of features.
    #
    # Each class has the appropriate attributes and type constraints to ensure that the data conforms to the GeoJSON specification.
    #
    # To use these classes, you would typically create instances like this:
    #
    # ```perl
    # use GeoJSON::Point;
    # use GeoJSON::Feature;
    # use GeoJSON::FeatureCollection;
    #
    # my $point = GeoJSON::Point->new(coordinates => [100.0, 0.0]);
    #
    # my $feature = GeoJSON::Feature->new(
    #     geometry => $point,
    #     properties => { name => 'Example Point' }
    # );
    #
    # my $feature_collection = GeoJSON::FeatureCollection->new(
    #     features => [$feature]
    # );
    # ```
    #
    # This structure allows you to create and manipulate GeoJSON data in an object-oriented manner, with type checking provided by Moose.

  }
}

{  
  if ($ENV{VLLM_URL} and $ENV{VLLM_MODEL}) {

    my $vllm = Langertha::Engine::vLLM->new(
      url => $ENV{VLLM_URL},
      model => $ENV{VLLM_MODEL},
      system_prompt => $system_prompt,
    );

    my $prompt = 'Do you wanna build a snowman?';

    printf("\n\nTo vLLM: %s\n\n", $prompt);

    print($vllm->simple_chat($prompt));

  }
}

{
  if ($ENV{GROQ_API_KEY} and $ENV{GROQ_MODEL}) {

    my $groq = Langertha::Engine::Groq->new(
      api_key => $ENV{GROQ_API_KEY},
      model => $ENV{GROQ_MODEL},
      system_prompt => $system_prompt,
    );

    my $prompt = 'Do you wanna build a snowman?';

    printf("\n\nTo Groq: %s\n\n", $prompt);

    print($groq->simple_chat($prompt));

  }
}

{
  if ($ENV{DEEPSEEK_API_KEY}) {

    my $deepseek = Langertha::Engine::DeepSeek->new(
      api_key => $ENV{DEEPSEEK_API_KEY},
      system_prompt => $system_prompt,
    );

    my $prompt = 'Do you wanna build a snowman?';

    printf("\n\nTo DeepSeek: %s\n\n", $prompt);

    print($deepseek->simple_chat($prompt));

  }
}

{
  if ($ENV{MISTRAL_API_KEY}) {

    my $mistral = Langertha::Engine::Mistral->new(
      api_key => $ENV{MISTRAL_API_KEY},
      system_prompt => $system_prompt,
    );

    my $prompt = 'Do you wanna build a snowman?';

    printf("\n\nTo Mistral: %s\n\n", $prompt);

    print($mistral->simple_chat($prompt));

  }
}

exit 0;