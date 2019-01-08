package Kubernetes::REST::HTTPRequest;
  use Moo;
  use Types::Standard qw/Str HashRef/;

  has server => (is => 'ro', required => 1);
  has credentials => (is => 'ro');

  sub authenticate {
    my $self = shift;
    my $auth = $self->credentials;
    if (defined $auth) {
      $self->headers->{ Authorization } = 'Bearer ' . $auth->token;
    }
  }

  has uri => (is => 'rw', isa => Str);

  has method => (is => 'rw', isa => Str);
  has url => (is => 'rw', isa => Str, lazy => 1, default => sub {
    my $self = shift;
    my $base_url = $self->server->endpoint;
    my $uri = $self->uri;
    return "${base_url}${uri}";    
  });
  has headers => (is => 'rw', isa => HashRef, default => sub { {} });
  has parameters => (is => 'rw', isa => HashRef);
  has content => (is => 'rw', isa => Str);

1;
