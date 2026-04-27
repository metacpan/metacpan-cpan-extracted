package Langertha::Knarr::Handler::ACPClient;
# ABSTRACT: Steerboard handler that consumes a remote ACP (BeeAI) agent
our $VERSION = '1.100';
use Moose;
use Future::AsyncAwait;
use JSON::MaybeXS;
use HTTP::Request;
use Net::Async::HTTP;
use IO::Async::Loop;
use Langertha::Knarr::Response;

with 'Langertha::Knarr::Handler';


has url        => ( is => 'ro', isa => 'Str', required => 1 );  # base URL of ACP server
has agent_name => ( is => 'ro', isa => 'Str', required => 1 );
has model_id   => ( is => 'ro', isa => 'Str', lazy => 1, default => sub { $_[0]->agent_name } );

has loop => ( is => 'ro', lazy => 1, default => sub { IO::Async::Loop->new } );

has _http => ( is => 'ro', lazy => 1, builder => '_build_http' );
sub _build_http {
  my ($self) = @_;
  my $h = Net::Async::HTTP->new;
  $self->loop->add($h);
  return $h;
}

has _json => ( is => 'ro', default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) } );

sub _extract_text {
  my ($self, $run) = @_;
  return '' unless ref $run eq 'HASH';
  my @bits;
  for my $msg ( @{ $run->{output} || [] } ) {
    for my $part ( @{ $msg->{parts} || [] } ) {
      push @bits, ( $part->{content} // '' )
        if ( $part->{content_type} // '' ) =~ m{^text/};
    }
  }
  return join '', @bits;
}

async sub handle_chat_f {
  my ($self, $session, $request) = @_;
  my @user = grep { ($_->{role} // '') eq 'user' } @{ $request->messages };
  my $last = $user[-1] // { content => '' };

  my $body = {
    agent_name => $self->agent_name,
    mode       => 'sync',
    input      => [ {
      parts => [ { content_type => 'text/plain', content => $last->{content} // '' } ],
    } ],
  };

  ( my $base = $self->url ) =~ s{/$}{};
  my $http_req = HTTP::Request->new( POST => "$base/runs" );
  $http_req->header( 'Content-Type' => 'application/json' );
  $http_req->content( $self->_json->encode($body) );

  my $resp = await $self->_http->do_request( request => $http_req );
  die "ACP remote failed: " . $resp->status_line . "\n" unless $resp->is_success;

  my $data = $self->_json->decode( $resp->decoded_content );
  return Langertha::Knarr::Response->new(
    content => $self->_extract_text($data),
    model   => $self->model_id,
    raw     => $data,
  );
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

Langertha::Knarr::Handler::ACPClient - Steerboard handler that consumes a remote ACP (BeeAI) agent

=head1 VERSION

version 1.100

=head1 SYNOPSIS

    use Langertha::Knarr::Handler::ACPClient;

    my $handler = Langertha::Knarr::Handler::ACPClient->new(
        url        => 'https://some-acp-server.example',
        agent_name => 'my-agent',
    );

=head1 DESCRIPTION

Consumes a remote IBM/BeeAI Agent Communication Protocol (ACP) agent
as a Knarr backend. Each chat request is sent as a synchronous
C<POST /runs> with a single C<text/plain> input part; the returned
run's output text becomes the response.

Pair with a front-side Knarr speaking OpenAI to expose any ACP agent
to OpenAI-format clients.

=head2 url

Required. Base URL of the upstream ACP server (path C</runs> is
appended).

=head2 agent_name

Required. The C<agent_name> to send in each ACP run request.

=head2 model_id

Optional. Defaults to L</agent_name>.

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
