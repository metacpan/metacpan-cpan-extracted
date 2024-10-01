#!/usr/bin/env perl
# ABSTRACT: Audio transcription example

$|=1;

use FindBin;
use lib "$FindBin::Bin/../lib";

use utf8;
use open ':std', ':encoding(UTF-8)';
use strict;
use warnings;
use Path::Tiny;

use Langertha::Engine::Whisper;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Groq;

if ($ENV{OPENAI_API_KEY} || $ENV{GROQ_API_KEY}) {
  my @keys;
  push @keys, 'OPENAI_API_KEY' if $ENV{OPENAI_API_KEY};
  push @keys, 'GROQ_API_KEY' if $ENV{GROQ_API_KEY};
  warn "Will be using your ".join(", ", @keys)." environment variable(s), which may produce cost.";
  sleep 5;
}

{  
  if ($ENV{WHISPER_URL}) {
    my $start = time;

    my $whisper = Langertha::Engine::Whisper->new(
      url => $ENV{WHISPER_URL},
    );

    print($whisper->simple_transcription(path(__FILE__)->parent->child('sample.ogg'), language => 'en'));

    my $end = time;
    printf("\n -- %u seconds (%s)\n", ($end - $start), (
      $whisper->transcription_model || 'whisper at '.$ENV{WHISPER_URL}
    ));
  }
}

{  
  if ($ENV{OPENAI_API_KEY}) {
    my $start = time;

    my $openai = Langertha::Engine::OpenAI->new(
      api_key => $ENV{OPENAI_API_KEY},
    );

    print($openai->simple_transcription(path(__FILE__)->parent->child('sample.ogg'), language => 'en'));

    my $end = time;
    printf("\n -- %u seconds (%s)\n", ($end - $start), $openai->transcription_model);
  }
}

{
  if ($ENV{GROQ_API_KEY}) {
    my $start = time;

    my $groq = Langertha::Engine::Groq->new(
      api_key => $ENV{GROQ_API_KEY},
    );

    print($groq->simple_transcription(path(__FILE__)->parent->child('sample.ogg'), language => 'en'));

    my $end = time;
    printf("\n -- %u seconds (%s)\n", ($end - $start), $groq->transcription_model);
  }
}

exit 0;