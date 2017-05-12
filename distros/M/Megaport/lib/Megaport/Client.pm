package Megaport::Client;

use 5.10.0;
use strict;
use warnings;

our $VERSION = "1.00";

use Carp qw(carp cluck);
use JSON::XS;
use HTTP::Request;
use LWP::UserAgent;

use Class::Tiny qw(token uri no_verify debug errstr), {
  ua => sub { LWP::UserAgent->new(agent => __PACKAGE__ . '/' . $VERSION) }
};

sub login {
  my ($self, $args) = @_;

  if (exists $args->{token}) {
    $self->token($args->{token});
    return $self->no_verify ? $self : $self->verify;
  }

  if ($args->{username} && $args->{password}) {
    my $response = $self->ua->post($self->uri . '/login', {
      username => $args->{username},
      password => $args->{password}
    });

    $self->_dump_response($response) if $self->debug;

    my $obj;
    eval { $obj = decode_json $response->decoded_content };
    if ($@) {
      $self->errstr('LoginError: API did not return valid JSON') and return;
    }

    if (!$response->is_success || !$obj->{data}->{session}) {
      $self->errst('LoginError: ' . $obj->{message}) and return;
    }

    $self->token($obj->{data}->{session});
    return $self->no_verify ? $self : $self->verify;
  }
}

sub verify {
  my ($self) = @_;

  my $response = $self->ua->post($self->uri . '/login/' . $self->token);

  $self->_dump_response($response) if $self->debug;

  if (!$response->is_success) {
    $self->_dump_response($response) if $self->debug;
    $self->errstr('LoginError: Verifying session token failed')
  }

  return $self;
}

sub request {
  my ($self, $op, $path, %args) = @_;

  my $headers = [
    'X-Auth-Token' => $self->token,
    exists $args{headers} ? @{$args{headers}} : ()
  ];

  my $uri = $self->uri . $path;
  my $request = HTTP::Request->new($op => $uri, $headers);
  $request->content($args{content}) if $args{content};

  my $response = $self->ua->request($request);

  $self->_dump_response($response) if $self->debug;

  my $obj;
  eval { $obj = decode_json $response->decoded_content };
  if ($@) {
    $self->errstr('RequestError: API did not return valid JSON') and return;
  }

  if (!$response->is_success) {
    $self->errst('RequestError: ' . $obj->{message}) and return;
  }

  return $obj->{data};
}

sub _dump_response {
  my ($self, $response) = @_;

  my @error = split /\n/, $response->as_string;
  $_ = "  > $_" foreach @error;

  say STDERR "================ [ DEBUG ] ================";
  say STDERR '  > ' . $response->request->method . ' ' . $response->request->uri . "\n";
  say STDERR join("\n", @error);
  cluck if !$response->is_success;
  say STDERR "===========================================\n";
}

1;
__END__
=encoding utf-8
=head1 NAME

Megaport::Client

=head1 DESCRIPTION

This class provides a simple mechanism for making API calls and performing error handling and returning data in a well-known format intended for use in the rest of the L<Megaport> package.

=head1 METHODS

=head2 login

Performs the appropriate login action based on the credentials provided (C<username/password> or C<token>).

=head2 verify

If C<no_verify> is not set, this is called by C<login> to validate the token.

=head2 request

    # Simple GET
    my $data = $client->request(GEt => '/locations');

    # POST
    my $data = $client->request(POST => '/profile', content => encode_json($user));

Performs a HTTP request, arguments are similar to L<HTTP::Request> but trimmed. Creates a L<HTTP::Request> object with the right base URI and auth headers.

If C<debug> is set, this will also dump the response body to STDERR.

=head1 AUTHOR

Cameron Daniel E<lt>cdaniel@cpan.orgE<gt>

=cut
