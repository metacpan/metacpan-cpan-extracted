package Langertha::Knarr::Handler::A2AClient;
# ABSTRACT: Steerboard handler that consumes a remote A2A (Agent2Agent) agent
our $VERSION = '1.001';
use Moose;
use Future::AsyncAwait;
use JSON::MaybeXS;
use HTTP::Request;
use Data::UUID;
use Net::Async::HTTP;
use IO::Async::Loop;

with 'Langertha::Knarr::Handler';


has url => ( is => 'ro', isa => 'Str', required => 1 );

has model_id => ( is => 'ro', isa => 'Str', default => 'a2a-remote' );

has loop => (
  is => 'ro',
  lazy => 1,
  default => sub { IO::Async::Loop->new },
);

has _http => (
  is => 'ro',
  lazy => 1,
  builder => '_build_http',
);

sub _build_http {
  my ($self) = @_;
  my $h = Net::Async::HTTP->new;
  $self->loop->add($h);
  return $h;
}

has _json => ( is => 'ro', default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) } );
has _uuid => ( is => 'ro', default => sub { Data::UUID->new } );

sub _extract_text {
  my ($self, $task) = @_;
  return '' unless ref $task eq 'HASH';
  # Prefer artifacts with text parts; fall back to status.message.
  my @bits;
  for my $art ( @{ $task->{artifacts} || [] } ) {
    for my $part ( @{ $art->{parts} || [] } ) {
      push @bits, ($part->{text} // '') if ($part->{type} // '') eq 'text';
    }
  }
  unless ( @bits ) {
    my $msg = $task->{status}{message} // {};
    for my $part ( @{ $msg->{parts} || [] } ) {
      push @bits, ($part->{text} // '') if ($part->{type} // '') eq 'text';
    }
  }
  return join '', @bits;
}

async sub handle_chat_f {
  my ($self, $session, $request) = @_;
  my @user = grep { ($_->{role} // '') eq 'user' } @{ $request->messages };
  my $last = $user[-1] // { content => '' };

  my $envelope = {
    jsonrpc => '2.0',
    id      => $self->_uuid->create_str,
    method  => 'tasks/send',
    params  => {
      id => $self->_uuid->create_str,
      sessionId => $session->id,
      message => {
        role => 'user',
        parts => [ { type => 'text', text => $last->{content} // '' } ],
      },
    },
  };

  my $http_req = HTTP::Request->new( POST => $self->url );
  $http_req->header( 'Content-Type' => 'application/json' );
  $http_req->content( $self->_json->encode($envelope) );

  my $resp = await $self->_http->do_request( request => $http_req );
  die "A2A remote failed: " . $resp->status_line . "\n" unless $resp->is_success;

  my $data = $self->_json->decode( $resp->decoded_content );
  if ( $data->{error} ) {
    die "A2A error: " . ( $data->{error}{message} // 'unknown' ) . "\n";
  }
  my $text = $self->_extract_text( $data->{result} );
  return { content => $text, model => $self->model_id };
}

sub list_models {
  my ($self) = @_;
  return [ { id => $self->model_id, object => 'model' } ];
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Handler::A2AClient - Steerboard handler that consumes a remote A2A (Agent2Agent) agent

=head1 VERSION

version 1.001

=head1 SYNOPSIS

    use Langertha::Knarr::Handler::A2AClient;

    my $handler = Langertha::Knarr::Handler::A2AClient->new(
        url => 'https://some-agent.example/',
    );

=head1 DESCRIPTION

Consumes a remote Google Agent2Agent (A2A) agent as a Knarr backend.
Each chat request is wrapped in a JSON-RPC 2.0 C<tasks/send> envelope
and POSTed to the upstream endpoint; the returned task's text artifacts
become the response.

Combined with a Knarr instance speaking OpenAI on the front side, this
turns Knarr into a universal protocol translator: OpenWebUI → Knarr
(OpenAI) → A2AClient → remote A2A agent.

=head2 url

Required. Base URL of the upstream A2A agent.

=head2 model_id

Optional. Defaults to C<a2a-remote>.

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
