package MCP::Server::Transport::HTTP;
use Mojo::Base 'MCP::Server::Transport', -signatures;

use Crypt::Misc  qw(random_v4uuid);
use Mojo::JSON   qw(to_json true);
use Mojo::Util   qw(dumper);
use Scalar::Util qw(blessed);

use constant DEBUG => $ENV{MCP_DEBUG} || 0;

sub handle_request ($self, $c) {
  my $method = $c->req->method;
  return $self->_handle_post($c) if $method eq 'POST';
  return $c->render(json => {error => 'Method not allowed'}, status => 405);
}

sub _extract_session_id ($self, $c) { return $c->req->headers->header('Mcp-Session-Id') }

sub _handle ($self, $data, $context) {
  warn "-- MCP Request\n@{[dumper($data)]}\n" if DEBUG;
  my $result = $self->server->handle($data, $context);
  warn "-- MCP Response\n@{[dumper($result)]}\n" if DEBUG && $result;
  return $result;
}

sub _handle_initialization ($self, $c, $data) {
  my $session_id = random_v4uuid;
  my $result     = $self->_handle($data, {});
  $c->res->headers->header('Mcp-Session-Id' => $session_id);
  $c->render(json => $result, status => 200);
}

sub _handle_post ($self, $c) {
  my $session_id = $self->_extract_session_id($c);

  return $c->render(json => {error => 'Invalid JSON'}, status => 400) unless my $data = $c->req->json;
  return $c->render(json => {error => 'Invalid JSON', status => 400}) unless ref $data eq 'HASH';

  if ($data->{method} && $data->{method} eq 'initialize') { $self->_handle_initialization($c, $data) }
  else                                                    { $self->_handle_regular_request($c, $data, $session_id) }
}

sub _handle_regular_request ($self, $c, $data, $session_id) {
  return $c->render(json => {error => 'Missing session ID'}, status => 400) unless $session_id;

  $c->res->headers->header('Mcp-Session-Id' => $session_id);
  return $c->render(data => '', status => 202)
    unless defined(my $result = $self->_handle($data, {session_id => $session_id, controller => $c}));

  # Sync
  return $c->render(json => $result, status => 200) if !blessed($result) || !$result->isa('Mojo::Promise');

  # Async
  $c->inactivity_timeout(0);
  $c->write_sse;
  $result->then(sub { $c->write_sse({text => to_json($_[0])})->finish });
}

1;

=encoding utf8

=head1 NAME

MCP::Server::Transport::HTTP - HTTP transport for MCP servers

=head1 SYNOPSIS

  use MCP::Server::Transport::HTTP;

  my $http = MCP::Server::Transport::HTTP->new;

=head1 DESCRIPTION

L<MCP::Server::Transport::HTTP> is a transport for MCP (Model Context Protocol) server that uses HTTP as the
underlying transport mechanism.

=head1 ATTRIBUTES

L<MCP::Server::Transport::HTTP> inherits all attributes from L<MCP::Server::Transport>.

=head1 METHODS

L<MCP::Server::Transport::HTTP> inherits all methods from L<MCP::Server::Transport> and implements the following new
ones.

=head2 handle_request

  $http->handle_request(Mojolicious::Controller->new);

Handles an incoming HTTP request.

=head1 SEE ALSO

L<MCP>, L<https://mojolicious.org>, L<https://modelcontextprotocol.io>.

=cut
