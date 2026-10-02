package Langertha::Knarr::PSGI::FakeReq;
# ABSTRACT: Header access on a PSGI environment, shaped like a Net::Async::HTTP::Server request
our $VERSION = '1.102';
use strict;
use warnings;


sub new {
  my ($class, $env) = @_;
  return bless { env => $env }, $class;
}


sub path { $_[0]{env}{PATH_INFO} // '/' }


sub header {
  my ($self, $name) = @_;
  ( my $key = uc $name ) =~ tr/-/_/;
  return $self->{env}{"HTTP_$key"};
}


# The request headers as [ name, value ] pairs, like
# Net::Async::HTTP::Server::Request->headers. PSGI keeps only the CGI form
# of a header name, so it comes back lower-cased with dashes (x-api-key).
sub headers {
  my ($self) = @_;
  my $env = $self->{env};
  my @pairs;
  for my $key ( sort keys %$env ) {
    my $name = $key =~ /\AHTTP_(.+)\z/ ? $1
      : $key =~ /\A(CONTENT_TYPE)\z/ ? $1 : next;
    ( $name = lc $name ) =~ tr/_/-/;
    push @pairs, [ $name, $env->{$key} ];
  }
  return @pairs;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::PSGI::FakeReq - Header access on a PSGI environment, shaped like a Net::Async::HTTP::Server request

=head1 VERSION

version 1.102

=head1 DESCRIPTION

Internal to L<Langertha::Knarr::PSGI>: wraps a PSGI C<$env> so the Knarr
code shared with the native server (auth check, protocol parsers, raw
passthrough) can read request headers and the path the way it reads them from a
L<Net::Async::HTTP::Server::Request>.

=head2 new

    my $req = Langertha::Knarr::PSGI::FakeReq->new($env);

=head2 path

    my $path = $req->path;   # /api/generate

The request path (C<PATH_INFO>), like
L<Net::Async::HTTP::Server::Request/path>; the Ollama protocol reads it to
tell C</api/generate> from C</api/chat>.

=head2 header

    my $value = $req->header('x-api-key');

The value of one request header, C<undef> when it was not sent.

=head2 headers

    for my $pair ( $req->headers ) { my ($name, $value) = @$pair; ... }

All request headers as C<[ name, value ]> pairs, names lower-cased with
dashes (PSGI keeps only the CGI form of a name).

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
