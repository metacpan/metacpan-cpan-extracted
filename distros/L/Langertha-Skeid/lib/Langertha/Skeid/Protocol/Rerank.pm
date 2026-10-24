package Langertha::Skeid::Protocol::Rerank;
our $VERSION = '0.004';
# ABSTRACT: The rerank routes -- relayed as the node speaks, translated for a TEI node
use strict;
use warnings;
use B ();
use Carp qw(croak);
use Scalar::Util qw(looks_like_number);
use Langertha::Skeid::Protocol::Refusal;


# The upstream dialects a node can be marked with (`rerank_format`), beside the default -- the
# shape the client speaks, relayed. Per dialect: whether its route sits at the server root
# rather than below /v1, and the methods that translate for it.
my %FORMAT = (
  tei => {
    at_server_root => 1,
    request        => '_tei_request',
    response       => '_tei_response',
    tokens         => '_tei_tokens',
  },
);


sub routes { return ('/rerank', '/v1/rerank') }


sub endpoint { '/v1/rerank' }


sub upstream_path { '/rerank' }


sub formats { return sort keys %FORMAT }


sub normalize_format {
  my ($class, $value) = @_;
  return '' unless defined $value;
  croak 'rerank_format must be a string' if ref $value;
  my $format = lc "$value";
  $format =~ s/\A\s+//;
  $format =~ s/\s+\z//;
  return '' unless length $format;
  return $format if $FORMAT{$format};
  croak "unknown rerank_format '$value' (expected one of: " . join(', ', $class->formats) . ')';
}


sub at_server_root {
  my ($class, $format) = @_;
  return ($FORMAT{$format // ''} || {})->{at_server_root} ? 1 : 0;
}


sub request_problem {
  my ($class, $body) = @_;
  return 'Invalid JSON body' unless ref($body) eq 'HASH';
  return "'model' must be a non-empty string"
    unless $class->_is_string($body->{model}) && length $body->{model};
  return "'query' must be a string" unless $class->_is_string($body->{query});
  return "'documents' must be a non-empty array"
    unless ref($body->{documents}) eq 'ARRAY' && @{$body->{documents}};
  return undef;
}


sub document_count {
  my ($class, $body) = @_;
  return 0 unless ref($body) eq 'HASH' && ref($body->{documents}) eq 'ARRAY';
  return scalar @{$body->{documents}};
}


sub request_to_upstream {
  my ($class, $body, $served_model, $format) = @_;
  my $spec = $FORMAT{$format // ''} or return { %$body, model => $served_model };
  my $method = $spec->{request};
  return $class->$method($body);
}


sub response_from_upstream {
  my ($class, $payload, $headers, $body, $served_model, $format) = @_;
  my $spec = $FORMAT{$format // ''} or croak __PACKAGE__ . '->response_from_upstream needs a format';
  my $method = $spec->{response};
  return $class->$method($payload, $headers, $body, $served_model);
}


sub usage {
  my ($class, $payload, $headers, $format) = @_;
  my $spec = $FORMAT{$format // ''};
  my $method = $spec ? $spec->{tokens} : '_body_tokens';
  my $tokens = $class->$method($payload, $headers);
  return undef unless defined $tokens;
  return { prompt_tokens => $tokens, completion_tokens => 0, total_tokens => $tokens };
}

# The token count in the body of an answer in the client's shape.
sub _body_tokens {
  my ($class, $payload) = @_;
  return undef unless ref($payload) eq 'HASH';
  if (ref(my $usage = $payload->{usage}) eq 'HASH') {
    for my $key (qw( prompt_tokens total_tokens )) {
      return 0 + $usage->{$key} if $class->_is_count($usage->{$key});
    }
  }
  my $tokens = ref($payload->{meta}) eq 'HASH' ? $payload->{meta}{tokens} : undef;
  return 0 + $tokens->{input_tokens}
    if ref($tokens) eq 'HASH' && $class->_is_count($tokens->{input_tokens});
  return undef;
}

#### TEI

sub _tei_request {
  my ($class, $body) = @_;
  my $documents = $body->{documents};
  my @texts;
  for my $index (0 .. $#$documents) {
    my $document = $documents->[$index];
    my $text = ref($document) eq 'HASH' ? $document->{text} : $document;
    Langertha::Skeid::Protocol::Refusal->refuse(
      "documents[$index] is not text: this model takes a string or an object with a string 'text'")
      unless $class->_is_string($text);
    push @texts, $text;
  }
  $class->_top_n($body);
  return {
    query => $body->{query},
    texts => \@texts,
    (exists $body->{return_documents} ? (return_text => ($body->{return_documents} ? \1 : \0)) : ()),
    (exists $body->{truncate} ? (truncate => $body->{truncate}) : ()),
  };
}

sub _tei_response {
  my ($class, $payload, $headers, $body, $served_model) = @_;
  die "The node's answer is not an array\n" unless ref($payload) eq 'ARRAY';
  my $count = $class->document_count($body);
  my $with_documents = $body->{return_documents} ? 1 : 0;

  my @results;
  for my $row (@$payload) {
    die "A result is not an object\n" unless ref($row) eq 'HASH';
    my ($index, $score) = @{$row}{qw( index score )};
    die "A result has no usable index or score\n"
      unless $class->_is_count($index) && $index < $count
      && defined($score) && !ref($score) && looks_like_number($score);
    push @results, {
      index           => 0 + $index,
      relevance_score => 0 + $score,
      ($with_documents && $class->_is_string($row->{text})
        ? (document => { text => $row->{text} })
        : ()),
    };
  }

  @results = sort {
    $b->{relevance_score} <=> $a->{relevance_score} || $a->{index} <=> $b->{index}
  } @results;
  my $top_n = $class->_top_n($body);
  splice(@results, $top_n) if $top_n && $top_n < @results;

  my $tokens = $class->_tei_tokens($payload, $headers);
  return {
    model   => $served_model,
    results => \@results,
    (defined $tokens ? (usage => { total_tokens => $tokens }) : ()),
  };
}

# TEI reports what it computed in response headers, not in the body.
sub _tei_tokens {
  my ($class, $payload, $headers) = @_;
  return undef unless $headers;
  my $tokens = $headers->header('x-compute-tokens');
  return $class->_is_count($tokens) ? 0 + $tokens : undef;
}

# The client's top_n as the number of results to keep: 0 for all of them, which is what no
# top_n, null and 0 ask for. Anything that is not a whole number of at least zero is refused.
sub _top_n {
  my ($class, $body) = @_;
  my $top_n = $body->{top_n};
  return 0 unless defined $top_n;
  Langertha::Skeid::Protocol::Refusal->refuse("'top_n' must be a whole number of at least 0")
    unless !ref($top_n) && $top_n =~ /\A[0-9]+\z/;
  return 0 + $top_n;
}

#### Values off the wire

# A JSON string, as opposed to a JSON number: a decoded number has a numeric value and no string
# value until something reads it as one, so this has to be asked before the value is used.
sub _is_string {
  my ($class, $value) = @_;
  return 0 unless defined($value) && !ref($value);
  my $flags = B::svref_2object(\$value)->FLAGS;
  return (($flags & (B::SVp_IOK | B::SVp_NOK)) && !($flags & B::SVp_POK)) ? 0 : 1;
}

# A whole number of at least zero: what a count off the wire has to be.
sub _is_count {
  my ($class, $value) = @_;
  return 0 unless defined($value) && !ref($value) && looks_like_number($value);
  return ($value >= 0 && $value < 9**9**9 && $value == int($value)) ? 1 : 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Protocol::Rerank - The rerank routes -- relayed as the node speaks, translated for a TEI node

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Serves C<POST /v1/rerank> and its alias C<POST /rerank>. Reranking has no OpenAI definition; the
shape clients speak is the one Cohere set and vLLM, Jina and infinity took over:

  { "model": "...", "query": "...", "documents": [ "...", ... ], "top_n": 3, "return_documents": true }

  { "results": [ { "index": 2, "relevance_score": 0.98, "document": { "text": "..." } }, ... ],
    "usage": { "total_tokens": 41 } }

It is a B<relayed route> (ADR 0021): a node that speaks this shape gets the client's body with
only C<model> replaced, and its answer goes back untouched. What differs between those nodes is
therefore left to differ -- C<document> is C<{ "text": ... }> on vLLM and Cohere and a plain
string on infinity, vLLM returns the documents whether asked or not.

One kind of node does not speak it at all: Hugging Face text-embeddings-inference (TEI), whose
only rerank route is C<POST /rerank> at the server root, taking C<query> and C<texts> and
answering a bare array of C<{ index, score, text }> in document order, its token count in a
response header. A node marked C<rerank_format: tei> is translated here, in both directions --
a translation on the B<upstream> side of the hub, where every other one sits on the client
side. This module is the only place that knows either wire: the field names of the request,
TEI's names, and the three places a reranker reports tokens.

Everything here is a class method.

=head2 routes

  my @paths = Langertha::Skeid::Protocol::Rerank->routes;

The client paths of the rerank route, sorted: C</rerank> and C</v1/rerank>. Both are one route.

=head2 endpoint

The C<endpoint> a rerank request's usage event carries, whichever spelling the client used:
C</v1/rerank>.

=head2 upstream_path

The path a rerank request is sent to at the node: C</rerank>, below the node's C</v1> or, for a
format L</at_server_root> names, at the server root.

=head2 formats

  my @names = Langertha::Skeid::Protocol::Rerank->formats;   # ('tei')

The values a node's C<rerank_format> can take, sorted.

=head2 normalize_format

  my $format = Langertha::Skeid::Protocol::Rerank->normalize_format($node{rerank_format});

A node's C<rerank_format> as it is kept: lowercased and trimmed, the empty string for none --
the node speaks the client's shape and is relayed. Croaks on a value that is not one of
L</formats>, so a misspelled format fails the config load instead of leaving a TEI node to be
called in a dialect it does not speak.

=head2 at_server_root

  my $root = Langertha::Skeid::Protocol::Rerank->at_server_root($format);

Whether a format's rerank route sits at the server root instead of below C</v1>. True for
C<tei>: a node URL written with or without a trailing C</v1> is called at C<{root}/rerank>.

=head2 request_problem

  my $problem = Langertha::Skeid::Protocol::Rerank->request_problem($c->req->json);

Why a decoded request body cannot be routed, as a message for the client, or C<undef> when it
can: a body that is not a JSON object, a C<model> that is not a non-empty string, a C<query>
that is not a string, C<documents> that is not a non-empty array. Checked before a node is
picked, so none of these costs a slot or a usage event. What a document may be is not checked
here -- that is the node's to say, and nodes differ.

=head2 document_count

  my $count = Langertha::Skeid::Protocol::Rerank->document_count($body);

How many documents a request carries: what the usage event records as C<documents>. Counted off
the request, so it is there whatever the node reports.

=head2 request_to_upstream

  my $upstream = Langertha::Skeid::Protocol::Rerank->request_to_upstream($body, $served_model, $format);

The body sent to the node. Without a format it is the client's own, every field as sent, with
C<model> replaced by the served model (an alias tier's, ADR 0008).

For C<tei> it is translated: C<query> as it is, C<documents> as C<texts> -- a document is a
string or an object with a string C<text> --, C<return_documents> as C<return_text> and
C<truncate> when the client sent them, and nothing else: TEI serves one model and takes no
C<model>, and C<top_n> is applied to the answer. A document that is not text, and a C<top_n>
that is not a whole number of at least zero, throw a L<Langertha::Skeid::Protocol::Refusal>
with a message for the client: such a request cannot be put to this node.

=head2 response_from_upstream

  my $answer = Langertha::Skeid::Protocol::Rerank->response_from_upstream(
    $payload, $headers, $body, $served_model, $format);

What the client gets for the answer of a node that has a format: C<$payload> is the decoded
answer, C<$headers> the L<Mojo::Headers> it came with, C<$body> the client's request. For
C<tei>, the bare array becomes

  { "model": <served model>,
    "results": [ { "index": 2, "relevance_score": 0.98, "document": { "text": "..." } }, ... ],
    "usage": { "total_tokens": 41 } }

sorted by score, highest first (equal scores in document order), cut to C<top_n> when that is
at least 1 (C<0>, C<null> and no C<top_n> are all of them). C<document> is there when the
client asked with C<return_documents> and the node returned the text; C<usage> when the node's
C<x-compute-tokens> header carries a count. Dies on an answer that is not such an array -- the
proxy answers that as a failed translation. A node without a format is not translated and this
is not called for it.

=head2 usage

  my $usage = Langertha::Skeid::Protocol::Rerank->usage($payload, $headers, $format);
  # { prompt_tokens => 41, completion_tokens => 0, total_tokens => 41 }, or undef

The tokens a rerank answer reports, as the usage block of the one dialect Skeid meters
(C<metrics.normalize>), or C<undef> when the node reported none. A reranker generates nothing,
so what it counts is input: the block carries the count as C<prompt_tokens> and as the total,
and the model's C<input_per_million> prices it.

Where the count is read: C<usage.prompt_tokens>, else C<usage.total_tokens> (vLLM, infinity,
Jina; older vLLM and Jina report only the total); else C<meta.tokens.input_tokens> (Cohere);
for a C<tei> node the C<x-compute-tokens> response header. A value that is not a whole number
of at least zero counts as not reported. Cohere's C<meta.billed_units.search_units> is not read:
it is not a token count. infinity counts characters, not tokens, unless it runs with
C<lengths_via_tokenize> -- Skeid records what the node says.

=head1 SEE ALSO

L<Langertha::Skeid::Proxy/Rerank route>, L<Langertha::Skeid::Protocol::Audio>,
L<Langertha::Skeid::Protocol>, L<Langertha::Skeid/Pluggable Usage Storage>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
