package Kubernetes::REST::HTTPTinyIO;
our $VERSION = '1.103';
# ABSTRACT: HTTP client using HTTP::Tiny
use Moo;
use HTTP::Tiny;
use IO::Socket::SSL;
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

    my %options;
    $options{ SSL_verify_mode } = SSL_VERIFY_PEER if ($self->ssl_verify_server);

    if (defined $self->ssl_cert_pem) {
        $options{ SSL_cert } = [ IO::Socket::SSL::Utils::PEM_string2cert($self->ssl_cert_pem) ];
    } elsif (defined $self->ssl_cert_file) {
        $options{ SSL_cert_file } = $self->ssl_cert_file;
    }

    if (defined $self->ssl_key_pem) {
        $options{ SSL_key } = IO::Socket::SSL::Utils::PEM_string2key($self->ssl_key_pem);
    } elsif (defined $self->ssl_key_file) {
        $options{ SSL_key_file } = $self->ssl_key_file;
    }

    if (defined $self->ssl_ca_pem) {
        $options{ SSL_ca } = [ IO::Socket::SSL::Utils::PEM_string2cert($self->ssl_ca_pem) ];
    } elsif (defined $self->ssl_ca_file) {
        $options{ SSL_ca_file } = $self->ssl_ca_file;
    }

    return HTTP::Tiny->new(
      agent => 'Kubernetes::REST Perl Client ' . ($Kubernetes::REST::VERSION // 'dev'),
      timeout => $self->timeout,
      SSL_options => \%options,
    );
});


sub call {
    my ($self, $req) = @_;


    my $res = $self->ua->request(
      $req->method,
      $req->url,
      {
        headers => $req->headers,
        (defined $req->content) ? (content => $req->content) : (),
      }
    );

    return Kubernetes::REST::HTTPResponse->new(
       status => $res->{ status },
       (defined $res->{ content })?( content => $res->{ content } ) : (),
    );
  }

sub call_streaming {
    my ($self, $req, $data_callback) = @_;


    my $res = $self->ua->request(
      $req->method,
      $req->url,
      {
        headers => $req->headers,
        data_callback => $data_callback,
      }
    );

    return Kubernetes::REST::HTTPResponse->new(
       status => $res->{ status },
       (defined $res->{ content })?( content => $res->{ content } ) : (),
    );
  }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::HTTPTinyIO - HTTP client using HTTP::Tiny

=head1 VERSION

version 1.103

=head1 SYNOPSIS

    use Kubernetes::REST::HTTPTinyIO;

    my $io = Kubernetes::REST::HTTPTinyIO->new(
        ssl_verify_server => 1,
        ssl_ca_file => '/path/to/ca.crt',
    );

=head1 DESCRIPTION

HTTP client implementation using L<HTTP::Tiny> for making Kubernetes API requests. Lighter alternative to L<Kubernetes::REST::LWPIO>.

=head2 ssl_verify_server

Boolean. Whether to verify the server's SSL certificate. Defaults to true.

=head2 timeout

Timeout in seconds for HTTP requests. Defaults to 310 (slightly more than the Kubernetes default watch timeout of 300s).

=head2 ua

The underlying L<HTTP::Tiny> instance.

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

=item * L<Kubernetes::REST::LWPIO> - LWP::UserAgent backend (default)

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
