package Langertha::Knarr::Protocol::Ollama;
# ABSTRACT: Ollama-compatible wire protocol (/api/chat, /api/tags) for Knarr

our $VERSION = '1.000';
use Moose;
use JSON::MaybeXS;
use Time::HiRes qw( time );
use POSIX qw( strftime );
use Langertha::Knarr::Request;

with 'Langertha::Knarr::Protocol';

# --- Streaming model ---
# Ollama streams via newline-delimited JSON (NDJSON), NOT SSE.
# Each chunk: { model, created_at, message:{role,content}, done:false }
# Final:     { model, created_at, message:{role,content:""}, done:true,
#              total_duration, eval_count, ... }
# Content-Type stays application/x-ndjson (or application/json with chunked).
# ----------------------

has steerboard => ( is => 'ro', weak_ref => 1 );
has _json => ( is => 'ro', default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) } );

sub protocol_name { 'ollama' }

sub protocol_routes {
  return [
    { method => 'POST', path => '/api/chat',     action => 'chat'   },
    { method => 'POST', path => '/api/generate', action => 'chat'   },
    { method => 'GET',  path => '/api/tags',     action => 'models' },
    { method => 'GET',  path => '/api/version',  action => 'version' },
  ];
}

sub _ts { strftime( "%Y-%m-%dT%H:%M:%S.000000000Z", gmtime ) }

sub parse_chat_request {
  my ($self, $http_req, $body_ref) = @_;
  my $data = $self->_json->decode( $$body_ref || '{}' );
  my @msgs;
  if ( $data->{messages} ) {
    @msgs = @{ $data->{messages} };
  }
  elsif ( defined $data->{prompt} ) {
    @msgs = ( { role => 'user', content => $data->{prompt} } );
  }
  return Langertha::Knarr::Request->new(
    protocol => 'ollama',
    raw      => $data,
    model    => $data->{model},
    messages => \@msgs,
    stream   => exists $data->{stream} ? ( $data->{stream} ? 1 : 0 ) : 1,  # Ollama defaults to stream
    temperature => $data->{options}{temperature},
  );
}

sub format_chat_response {
  my ($self, $response, $request) = @_;
  my $content = ref $response eq 'HASH' ? $response->{content} : "$response";
  my $payload = {
    model      => $request->model // 'steerboard',
    created_at => _ts(),
    message    => { role => 'assistant', content => $content },
    done       => JSON::MaybeXS::true(),
    done_reason => 'stop',
  };
  return ( 200, { 'Content-Type' => 'application/json' }, $self->_json->encode($payload) );
}

sub format_models_response {
  my ($self, $models) = @_;
  my @data = map {
    my $id = ref $_ eq 'HASH' ? $_->{id} : "$_";
    { name => $id, model => $id, modified_at => _ts(), size => 0 }
  } @$models;
  return ( 200, { 'Content-Type' => 'application/json' },
    $self->_json->encode({ models => \@data }) );
}

sub format_stream_chunk {
  my ($self, $delta_text, $request) = @_;
  my $payload = {
    model      => $request->model // 'steerboard',
    created_at => _ts(),
    message    => { role => 'assistant', content => $delta_text },
    done       => JSON::MaybeXS::false(),
  };
  return $self->_json->encode($payload) . "\n";
}

sub stream_content_type { 'application/x-ndjson' }

sub format_stream_done {
  my ($self, $request) = @_;
  my $payload = {
    model      => $request->model // 'steerboard',
    created_at => _ts(),
    message    => { role => 'assistant', content => '' },
    done       => JSON::MaybeXS::true(),
    done_reason => 'stop',
  };
  return $self->_json->encode($payload) . "\n";
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Protocol::Ollama - Ollama-compatible wire protocol (/api/chat, /api/tags) for Knarr

=head1 VERSION

version 1.000

=head1 DESCRIPTION

Implements the Ollama wire format on top of
L<Langertha::Knarr::Protocol>. Loaded by default.

=over

=item * C<POST /api/chat>, C<POST /api/generate> — chat with NDJSON streaming

=item * C<GET /api/tags> — model listing

=item * C<GET /api/version> — version probe

=back

Streaming uses newline-delimited JSON (NDJSON) rather than SSE — the
C<Content-Type> is C<application/x-ndjson> and each chunk is a single
JSON object per line. The final chunk has C<done: true>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

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
