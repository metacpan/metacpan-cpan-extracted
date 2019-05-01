package Furl::PSGI::HTTP;
$Furl::PSGI::HTTP::VERSION = '0.03';
# ABSTRACT: Furl's low-level interface, wired to PSGI

use warnings;
use strict;

use Carp ();
use HTTP::Parser::XS;
use HTTP::Message::PSGI ();

use parent 'Furl::HTTP';


sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);

  defined $self->{app}
    or Carp::croak "'app' attribute must be provided";

  $self;
}

sub connect { 1 }

*connect_ssl = *connect_ssl_over_proxy = \&connect;

sub write_all {
  my ($self, $sock, $p, $timeout_at) = @_;
  
  $self->{request} = '' if !exists $self->{request};
  $self->{request} .= $p;

  1;
}

sub read_timeout {
  my ($self, $sock, $bufref, $len, $off, $timeout_at) = @_;

  if (my $request = delete $self->{request}) {
    my $env = {};
    my $ret = HTTP::Parser::XS::parse_http_request($request, $env);
    if ($ret && $ret < 0) {
      Carp::confess "Error $ret trying to parse buffered HTTP request";
    }
    
    my $res = eval { $self->{app}->($env) }
      || $self->_psgi500($@);

    my $response = 
      'HTTP/1.1 ' . HTTP::Message::PSGI::res_from_psgi($res)->as_string("\015\012");

    $$bufref = $response;
    return length($response);
  }

  0;
}

sub _psgi500 {
  my ($self, $e) = @_;
  my $body = "Internal Response: $e";
  [
    500,
    [
      'X-Internal-Response' => 1,
      'Content-Type'        => 'text/plain',
      'Content-Length'      => length($body)
    ],
    [$body]
  ]
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Furl::PSGI::HTTP - Furl's low-level interface, wired to PSGI

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Furl::PSGI::HTTP;

  my $res = Furl::PSGI::HTTP->new(app => $my_app)->request(
    method => 'POST',
    url    => 'https://foo.baz.net/etc',
    headers => [
      'Content-Type' => 'application/json',
    ],
    content => encode_json {
      type => 'dog',
      breed => 'chihuahua',
    },
  );

=head1 DESCRIPTION

This is where the magic happens for L<Furl::PSGI>, similar to L<Furl> and
L<Furl::HTTP>.  Given a PSGI app, all requests are sent to it and no network
connections should be made.

=head1 METHODS

=head2 new

Supports all options in L<Furl::HTTP/new>, and additionally requires an C<app>
attribute which should be a L<PSGI> app (a code ref), which will receive ALL
requests handled by the C<Furl::PSGI::HTTP> instance returned.

=head1 INHERITANCE

Furl::PSGI::HTTP
  is a L<Furl::HTTP>

=head1 NOTES

L<Furl::HTTP> does a ton of work inside L<Furl::HTTP/request>.  In order to
capture all of the behavior of Furl, and to avoid having to keep up with any
changes, I didn't want to reimplement C<request>.  Instead, we turn all of the
C<connect> methods into stubs, and change C<write_all> to build an internal
buffer of the request as a string, as well as change C<read_timeout> into
a method that takes the buffered request, parses it, invokes the PSGI app, then
turns the PSGI response into a string to pretend we're getting an HTTP reply
back on a socket.  This has its own stability risks as Furl changes, but it's
much, much simpler than taking on all work that happens in C<request>.

=head1 AUTHOR

Meredith Howard <mhoward@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Meredith Howard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
