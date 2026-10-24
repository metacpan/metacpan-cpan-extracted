package Langertha::Skeid::Protocol::MCP;
our $VERSION = '0.004';
# ABSTRACT: The MCP gateway's wire -- relayed headers, upstream URLs and the server listing
use strict;
use warnings;
use Mojo::URL;


# The transports a server entry can name. Only one of them is relayed; the other is a hint for
# a server on the customer's own machine.
my %TRANSPORT = (
  'streamable-http' => { relayed => 1 },
  'stdio'           => { relayed => 0 },
);

# The client's request headers that travel upstream, beside every Mcp-* one. Nothing else of
# the client's does -- its Authorization least of all.
my %REQUEST_HEADER = map { $_ => 1 } qw( content-type accept last-event-id );

# Header names a server's static `headers:` may not set, and why. A credential in the config
# would be a secret on disk (ADR 0003); the rest belong to the relay or to the connection.
my $CREDENTIAL = 'a credential is named by api_key_ref or api_key_env, never written into the config';
my $RELAYED    = 'the relay passes it on from the client';
my $FRAMING    = 'it belongs to the connection';
my %CONFIG_HEADER_PROBLEM = (
  (map { $_ => $CREDENTIAL } qw( authorization proxy-authorization x-api-key cookie )),
  (map { $_ => $RELAYED } keys %REQUEST_HEADER),
  (map { $_ => $FRAMING } qw( host content-length transfer-encoding content-encoding accept-encoding
    connection keep-alive te trailer upgrade expect )),
);

# The upstream's response headers that reach the client, beside every Mcp-* one. Whatever else
# the server sets -- cookies, Server, CORS, HSTS -- is about the server and its own site, not
# for a client of this gateway. WWW-Authenticate is not here: it would come only with an
# upstream 401, which is answered 502 and never relayed.
my %RESPONSE_HEADER = map { $_ => 1 } qw( content-type cache-control retry-after );


sub response_header_allowed {
  my ($class, $name) = @_;
  my $lc = lc($name // '');
  return ($RESPONSE_HEADER{$lc} || $lc =~ /\Amcp-/) ? 1 : 0;
}


sub transports { return sort keys %TRANSPORT }


sub default_transport { 'streamable-http' }


sub is_transport {
  my ($class, $transport) = @_;
  return (defined($transport) && !ref($transport) && $TRANSPORT{$transport}) ? 1 : 0;
}


sub is_relayed {
  my ($class, $transport) = @_;
  return ($class->is_transport($transport) && $TRANSPORT{$transport}{relayed}) ? 1 : 0;
}


sub listing_path { '/v1/mcp/servers' }


sub endpoint {
  my ($class, $name) = @_;
  return '/mcp/' . $name;
}


sub name_problem {
  my ($class, $name) = @_;
  return undef if defined($name) && !ref($name) && $name =~ /\A[A-Za-z0-9][A-Za-z0-9._-]{0,63}\z/;
  return 'a server name must start with a letter or digit and hold only letters, digits, ".", '
    . '"_" and "-", at most 64 characters: it is the <name> of /mcp/<name>';
}


sub url_problem {
  my ($class, $url) = @_;
  my $parsed = (defined($url) && !ref($url) && length($url)) ? Mojo::URL->new("$url") : undef;
  return 'must be an absolute http or https URL'
    unless $parsed && ($parsed->scheme // '') =~ /\Ahttps?\z/i && length($parsed->host // '');
  return 'must not carry credentials: an upstream key is named by api_key_ref or api_key_env'
    if defined $parsed->userinfo;
  return undef;
}


sub config_header_problem {
  my ($class, $name) = @_;
  my $lc = lc($name // '');
  return $RELAYED if $lc =~ /\Amcp-/;
  return $CONFIG_HEADER_PROBLEM{$lc};
}


sub request_headers {
  my ($class, $headers) = @_;
  my %out;
  for my $name (@{$headers->names}) {
    my $lc = lc($name);
    next unless $REQUEST_HEADER{$lc} || $lc =~ /\Amcp-/;
    $out{$name} = $headers->header($name);
  }
  return %out;
}


sub upstream_url {
  my ($class, $base, $rest, $query) = @_;
  my $url = Mojo::URL->new($base);

  if (defined($rest) && length($rest)) {
    my @segments = split m{/}, $rest, -1;
    my $trailing = (@segments && $segments[-1] eq '') ? 1 : 0;
    pop @segments if $trailing;
    for my $segment (@segments) {
      return undef if $segment eq '.' || $segment eq '..' || $segment =~ /\\/;
    }
    if (@segments) {
      my $path = $url->path;
      push @{$path->parts}, @segments;
      $path->trailing_slash($trailing);
    }
  }

  $url->query->append(@{$query->pairs}) if $query && @{$query->pairs};
  return $url;
}


sub listing_entry {
  my ($class, $server, $base) = @_;
  my %entry = (
    name        => $server->{name},
    transport   => $server->{transport},
    description => ($server->{description} // ''),
  );
  if ($class->is_relayed($server->{transport})) {
    $entry{url} = ($base // '') . $class->endpoint($server->{name});
  } else {
    $entry{command} = $server->{command};
    $entry{args}    = [ @{$server->{args} || []} ];
    $entry{env}     = { %{$server->{env} || {}} };
  }
  return \%entry;
}


sub is_event_stream {
  my ($class, $content_type) = @_;
  return (defined($content_type) && $content_type =~ m{\A\s*text/event-stream\s*(?:;|\z)}i) ? 1 : 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Protocol::MCP - The MCP gateway's wire -- relayed headers, upstream URLs and the server listing

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Skeid relays MCP's "Streamable HTTP" transport to the MCP servers a customer key was assigned
(ADR 0022): C<POST>, C<GET> and C<DELETE> on C</mcp/E<lt>nameE<gt>>, and a listing of a key's
servers on C</v1/mcp/servers>. It does not read MCP -- no JSON-RPC, no tool list, no session
state. What it has to know of the wire is small and is all here: which transports a server
entry may name, which request headers travel upstream, how a sub-path becomes an upstream URL,
and what a listing entry looks like.

  { "object": "list", "data": [
    { "name": "bookrag", "transport": "streamable-http",
      "url": "https://llm.example.com/mcp/bookrag", "description": "..." },
    { "name": "files", "transport": "stdio", "command": "mcp-files",
      "args": ["--root", "/srv/data"], "env": {}, "description": "..." } ] }

Everything here is a class method. The config section is L<Langertha::Skeid/mcp>, the routes
are L<Langertha::Skeid::Proxy/MCP routes>.

=head2 response_header_allowed

  my $passes = Langertha::Skeid::Protocol::MCP->response_header_allowed($name);

Whether a response header of the MCP server is relayed to the client: C<Content-Type>,
C<Cache-Control>, C<Retry-After> and every C<Mcp-*> header. An allowlist, not a filter: a header
the server adds tomorrow does not reach the client until it is named here.

=head2 transports

  my @names = Langertha::Skeid::Protocol::MCP->transports;   # ('stdio', 'streamable-http')

The transports a server entry may name, sorted.

=head2 default_transport

The transport of an entry that names none: C<streamable-http>.

=head2 is_transport

  my $known = Langertha::Skeid::Protocol::MCP->is_transport($name);

Whether a server entry may name this transport.

=head2 is_relayed

  my $proxied = Langertha::Skeid::Protocol::MCP->is_relayed($transport);

Whether Skeid relays a server of this transport. True for C<streamable-http>; a C<stdio> server
runs on the customer's machine, and its entry is a hint in the listing and nothing else.

=head2 listing_path

The client path of the listing: C</v1/mcp/servers>.

=head2 endpoint

  my $path = Langertha::Skeid::Protocol::MCP->endpoint('bookrag');   # /mcp/bookrag

The client path of a server, which is also the C<endpoint> its usage events carry -- whatever
sub-path a request named.

=head2 name_problem

  my $problem = Langertha::Skeid::Protocol::MCP->name_problem($name);   # undef when it is fine

A server name is one segment of a URL path and a part of a usage event's C<endpoint>: it starts
with a letter or digit and holds only letters, digits, C<.>, C<_> and C<->, at most 64
characters. Returns what is wrong with a name, or nothing.

=head2 url_problem

  my $problem = Langertha::Skeid::Protocol::MCP->url_problem($url);   # undef when it is fine

What is wrong with a configured URL -- a server's C<url> or the section's C<public_url> -- or
nothing: it has to be an absolute C<http> or C<https> URL, and it may not carry credentials
(C<user:password@>), which would be a secret in the config. The message never repeats the URL.

=head2 config_header_problem

  my $problem = Langertha::Skeid::Protocol::MCP->config_header_problem('Authorization');

Why a header may not be among a server's static C<headers>, or nothing when it may. Refused are
the credential headers (C<Authorization>, C<Proxy-Authorization>, C<X-Api-Key>, C<Cookie>), the
headers L</request_headers> passes on from the client, and the ones that belong to the
connection.

=head2 request_headers

  my %headers = Langertha::Skeid::Protocol::MCP->request_headers($c->req->headers);

The client's headers that go upstream, by the name the client used: C<Content-Type>, C<Accept>,
C<Last-Event-ID> and every header whose name starts with C<Mcp-> (C<Mcp-Session-Id>,
C<Mcp-Protocol-Version>, whatever the protocol adds there). An allowlist: the client's
C<Authorization>, C<X-Api-Key>, cookies and forwarding headers are not on it.

=head2 upstream_url

  my $url = Langertha::Skeid::Protocol::MCP->upstream_url($server->{url}, $rest, $c->req->url->query);

The L<Mojo::URL> a request is relayed to: the server's configured URL, with the sub-path the
client named after C</mcp/E<lt>nameE<gt>/> appended to its path segment by segment and the
client's query parameters appended to its query. C<$rest> is the decoded sub-path, or nothing.

Returns nothing for a sub-path with a C<.> or C<..> segment or a backslash in it. Such a path
is refused rather than normalised: a customer key must not climb out of the path the operator
configured, whatever the upstream's own idea of path normalisation is.

=head2 listing_entry

  my $entry = Langertha::Skeid::Protocol::MCP->listing_entry($server, 'https://llm.example.com');

What the listing says about one resolved server (L<Langertha::Skeid/mcp_servers>): C<name>,
C<transport> and C<description> always; for a relayed server its public C<url>,
C<{base}/mcp/{name}>; for a C<stdio> one C<command>, C<args> and C<env>. Never the upstream
URL, the key reference, the variable name or the static headers.

=head2 is_event_stream

  my $open_ended = Langertha::Skeid::Protocol::MCP->is_event_stream($res->headers->content_type);

Whether an answer is a Server-Sent Events stream, by its media type. Such an answer has no end
Skeid could check without reading MCP, so however it ends is how it ends.

=head1 SEE ALSO

L<Langertha::Skeid/mcp> (the config section), L<Langertha::Skeid::Proxy/MCP routes>

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
