#!/usr/bin/env perl
# ABSTRACT: OpenAI/Ollama Structured Code Output

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

my $jsonschema = {
  type => 'object',
  properties => {
    description => {
      type => 'string',
      description => 'reflection of the query the user has given',
    },
    planning => {
      type => 'string',
      description => 'explains the reasoning behind the specific structure',
    },
    notes => {
      type => 'string',
      description => 'additional notes for after the generation',
    },
    files => {
      type => 'array',
      items => {
        type => 'object',
        properties => {
          filename => {
            type => 'string',
            description => 'filename of the new or modified file',
          },
          directory => {
            type => 'string',
            description => 'directory inside the project of the new or modified file or empty if its a file in root',
          },
          remove => {
            type => 'boolean',
            description => 'remove the file from the project',
          },
          content => {
            type => 'string',
            description => 'new content of the file',
          },
          reason => {
            type => 'string',
            description => 'explain why this file has to be added, modified or removed',
          },
          description => {
            type => 'string',
            description => 'description of the file that later will be given again to the model on modifications of the files',
          },
          executable => {
            type => 'boolean',
            description => 'should the resulting file be executable',
          },
        },
        required => [qw( filename directory content reason description executable remove )],
        additionalProperties => JSON->false,
      },
    },
  },
  required => [qw( files planning notes )],
  additionalProperties => JSON->false,
};

if ($ENV{OLLAMA_URL}) {

  my $ollama = Langertha::Engine::Ollama->new(
    model => ( $ENV{OLLAMA_MODEL} || 'deepseek-coder-v2:latest' ),
    url => $ENV{OLLAMA_URL},
    content_size => ( 2 * 1024 ),
    temperature => 0,
    system_prompt => <<__EOP__,

__EOP__

# You are a helpful software developer. You write always python.
  );

  my $structured = $ollama->openai( response_format => {
    type => "json_schema",
    json_schema => {
      name => "codefiles",
      schema => $jsonschema,
      strict => JSON->true,
    },
  });

  my $structstart = time;

# which files would be needed to start a project that has several components like a master server, a webserver, a windows client, a cli client and so on?
  my $result = $structured->simple_chat(<<__EOP__);

How to take a walk in the park

__EOP__

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

exit 0;