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
    sentences => {
      type => 'array',
      items => {
        type => 'object',
        properties => {
          subject => {
            type => 'string',
          },
          verb => {
            type => 'string',
          },
          object => {
            type => 'string',
          },
        },
        required => [qw( subject verb object )],
        additionalProperties => JSON->false,
      },
    },
  },
  required => [qw( sentences )],
  additionalProperties => JSON->false,
};

if ($ENV{OLLAMA_URL}) {

  my $ollama = Langertha::Engine::Ollama->new(
    model => ( $ENV{OLLAMA_MODEL} || 'llama3.1:8b' ),
    url => $ENV{OLLAMA_URL},
    content_size => ( 4 * 1024 ),
    temperature => 0.5,
    system_prompt => <<__EOP__,

You will process the provided text by splitting it into independent, clear sentences. Additionally, ensure that any pronouns (such as "he," "she," "it," "they," etc.) are replaced with the specific entities or individuals they refer to, wherever possible, to eliminate confusion. The output must follow a precise, data-driven format, as the sentences are used strictly for data gathering and not for human consumption or readability.

Pronoun Replacement:

Identify the entity (person, group, or object) each pronoun refers to.
Replace every pronoun with its corresponding entity to ensure clarity and avoid ambiguity.
Sentence Splitting:

Break down long or compound sentences into shorter, standalone sentences.
Ensure that each sentence expresses a single idea or action clearly, without relying on the context of other sentences.
Translation to English:

Regardless of the original language of the text, always translate the sentences into English. Maintain the accuracy of information during translation but avoid adding any human-like nuances or readability enhancements.
Data-Centric Focus:

The sentences are intended purely for data collection and not for human interaction. There should be no focus on stylistic elements, flow, or emotional tone. The goal is clarity and factual accuracy.
Non-Human Usability:

The sentences will not be used by humans and should not contain any embellishments, colloquialisms, or subjective interpretations. The output should be highly structured and straightforward, optimized for machine use rather than human readability.
Clarifying Relationships:

Ensure that each sentence explicitly states the relationships between subjects, objects, and actions.
If a sentence contains multiple ideas or subjects, split them into individual sentences with clear and unambiguous references to the relevant entities or actions.

__EOP__

# You will break the provided sentences into logical units, paying special attention to how subjects, objects, and predicates are structured.

# Sentence Structure: Each sentence should be analyzed in terms of its subjects, objects, and one verb.

# Subjects and Objects Grouping: When subjects or objects are combined in a sentence (for example, multiple entities performing or receiving the same action), you will group them together as a single unit.

# Multiple Independent Actions: If a sentence contains multiple subjects that perform independent actions (i.e., they are not related by the same verb), each subject must be separated into its own sentence, with its corresponding action and object clearly identified.

# Handling Multiple Subjects: When multiple subjects are doing different things in a sentence, treat each one as a separate logical unit. Each subject will have its own sentence, with a focus on describing what that particular subject does, and the object(s) involved (if any).

# Clarification of Relationships: Ensure that each logical unit clearly states the relationships between subjects, objects, and the actions they are involved in. Avoid combining unrelated elements into a single sentence unless they share a direct relationship.

# ALWAYS translate to English.

# ALWAYS response in JSON.

  );

  my $structured = $ollama->openai( response_format => {
    type => "json_schema",
    json_schema => {
      name => "sentences_schema",
      schema => $jsonschema,
      strict => JSON->true,
    },
  });

  my $notstructured = $ollama->openai;

  my $structstart = time;

  my $result = $notstructured->simple_chat(<<__EOP__);

Die Forscher kritisieren an der Kommunikation speziell die komplizierten Sätze mit bis zu 50 Wörtern. Auch die Wörter selbst sind manchmal viel zu lang, zum Beispiel Wortmonster wie das Gesundheitsversorgungsweiterentwicklungsgesetz. In Deutschland lebende Ausländerinnen kennen dieses Problem besonders gut. Fast alle können von unverständlichen Behördenbriefen berichten.

Kein Wort, sondern eine Kurzgeschichte
Das kann auch der Brite Ian McMaster, der inzwischen außerdem einen deutschen Pass hat. Als der 62-Jährige vor rund 30 Jahren nach München kam, wollte das Standesamt für seine Heirat eine Eheunbedenklichkeitsbescheinigung. Mit dem Dokument beweist man, dass es keine rechtlichen Gründe gegen die Ehe gibt. „Das ist kein Wort – das ist eine Kurzgeschichte“, sagt McMaster und lacht.

Aber nicht immer kann man solche Situationen mit Humor sehen. Und vor allem: Was hilft, um diese spezielle Sprache zu verstehen? McMaster hat in seinen ersten Jahren im Land deutsche Freunde gefragt. Und gelernt, dass auch sie das Amtsdeutsch nicht immer verstehen. „Manchmal musste ich mehrere Leute fragen“, erzählt er.

Bei Verständnisproblemen und Unsicherheiten hat der Zuwanderer gute Erfahrungen gemacht, wenn er den direkten Kontakt zu den Ämtern suchte. „Ich rufe die Sachbearbeiterin oder den Sachbearbeiter an und fasse den Inhalt des Behördenbriefs in meinen eigenen Worten zusammen“, sagt McMaster. Wenn er etwas falsch verstanden hat, korrigiert ihn dann der Sachbearbeiter. „Das hilft mir sehr. Aber für so einen Anruf braucht man schon ganz gute Deutschkenntnisse.“

__EOP__

  my $structend = time;

  eval {
    my $res = JSON::MaybeXS->new->decode($result);
    print Dumper $res;
  };
  if ($@) {
    print Dumper $result;
    print STDERR $@;
  }

  printf("\n\n%u\n\n", $structend - $structstart);
}

exit 0;