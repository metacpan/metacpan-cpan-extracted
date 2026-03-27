package Kubernetes::REST::LWPIO;
our $VERSION = '1.103';
# ABSTRACT: HTTP client using LWP::UserAgent
use Moo;
use LWP::UserAgent;
use Kubernetes::REST::HTTPResponse;
use Types::Standard qw/Bool/;

with 'Kubernetes::REST::Role::IO';


has ssl_verify_server => (is => 'ro', isa => Bool, default => 1);


has ssl_cert_file => (is => 'ro');
has ssl_cert_pem  => (is => 'ro');
has ssl_key_file  => (is => 'ro');
has ssl_key_pem   => (is => 'ro');
has ssl_ca_file   => (is => 'ro');
has ssl_ca_pem    => (is => 'ro');

has timeout => (is => 'ro', default => sub { 310 });


has ua => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    require IO::Socket::SSL::Utils;

    my %ssl_opts;
    $ssl_opts{ verify_hostname } = $self->ssl_verify_server;
    $ssl_opts{ SSL_verify_mode } = $self->ssl_verify_server ? 1 : 0;

    # PEM data: convert to X509/EVP_PKEY objects via SSL_cert/SSL_key
    # PEM file paths: use SSL_cert_file/SSL_key_file as normal
    if (defined $self->ssl_cert_pem) {
        $ssl_opts{ SSL_cert } = [ IO::Socket::SSL::Utils::PEM_string2cert($self->ssl_cert_pem) ];
    } elsif (defined $self->ssl_cert_file) {
        $ssl_opts{ SSL_cert_file } = $self->ssl_cert_file;
    }

    if (defined $self->ssl_key_pem) {
        $ssl_opts{ SSL_key } = IO::Socket::SSL::Utils::PEM_string2key($self->ssl_key_pem);
    } elsif (defined $self->ssl_key_file) {
        $ssl_opts{ SSL_key_file } = $self->ssl_key_file;
    }

    if (defined $self->ssl_ca_pem) {
        $ssl_opts{ SSL_ca } = [ IO::Socket::SSL::Utils::PEM_string2cert($self->ssl_ca_pem) ];
    } elsif (defined $self->ssl_ca_file) {
        $ssl_opts{ SSL_ca_file } = $self->ssl_ca_file;
    }

    return LWP::UserAgent->new(
      agent => 'Kubernetes::REST Perl Client ' . ($Kubernetes::REST::VERSION // 'dev'),
      timeout => $self->timeout,
      ssl_opts => \%ssl_opts,
    );
});


sub call {
    my ($self, $req) = @_;


    my $http_req = HTTP::Request->new(
      $req->method,
      $req->url,
      [ %{$req->headers} ],
      $req->content,
    );

    my $res = $self->ua->request($http_req);

    return Kubernetes::REST::HTTPResponse->new(
       status => $res->code,
       (length $res->decoded_content) ? ( content => $res->decoded_content ) : (),
    );
  }

sub call_streaming {
    my ($self, $req, $data_callback) = @_;


    my $http_req = HTTP::Request->new(
      $req->method,
      $req->url,
      [ %{$req->headers} ],
    );

    my $res = $self->ua->request($http_req, sub {
      my ($chunk) = @_;
      $data_callback->($chunk);
    });

    return Kubernetes::REST::HTTPResponse->new(
       status => $res->code,
       (length $res->decoded_content) ? ( content => $res->decoded_content ) : (),
    );
  }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::LWPIO - HTTP client using LWP::UserAgent

=head1 VERSION

version 1.103

=head1 SYNOPSIS

    use Kubernetes::REST::LWPIO;

    my $io = Kubernetes::REST::LWPIO->new(
        ssl_verify_server => 1,
        ssl_ca_file => '/path/to/ca.crt',
    );

    # Access the LWP::UserAgent for debugging (e.g. with LWP::ConsoleLogger)
    use LWP::ConsoleLogger::Easy qw(debug_ua);
    debug_ua($io->ua);

=head1 DESCRIPTION

HTTP client implementation using L<LWP::UserAgent> for making Kubernetes API requests. This is the default IO backend for L<Kubernetes::REST>.

The C<ua> attribute is exposed so that debugging tools like L<LWP::ConsoleLogger> can be attached to inspect HTTP traffic.

=head2 ssl_verify_server

Boolean. Whether to verify the server's SSL certificate. Defaults to true.

=head2 timeout

Timeout in seconds for HTTP requests. Defaults to 310 (slightly more than the Kubernetes default watch timeout of 300s).

=head2 ua

The underlying L<LWP::UserAgent> instance. Access this to attach middleware such as L<LWP::ConsoleLogger> for HTTP debugging.

=head2 call

    my $response = $io->call($req);

Execute an HTTP request. Receives a fully prepared L<Kubernetes::REST::HTTPRequest> (URL, headers, content all set). Returns a L<Kubernetes::REST::HTTPResponse>.

=head2 call_streaming

    my $response = $io->call_streaming($req, sub { my ($chunk) = @_; ... });

Execute an HTTP request with streaming response. The C<$data_callback> is called with each chunk of data as it arrives.

Used internally by L<Kubernetes::REST/watch> for the Watch API.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST::Role::IO> - IO interface role

=item * L<Kubernetes::REST::HTTPTinyIO> - Alternative HTTP::Tiny backend

=item * L<LWP::ConsoleLogger> - HTTP debugging tool

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/kubernetes-rest/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
