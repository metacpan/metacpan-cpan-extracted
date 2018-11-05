package Docker::Registry::Response;
  use Moo;
  use Types::Standard qw/Str Int HashRef/;
  use HTTP::Headers;

  has content  => (is => 'ro', isa => Str);
  has status   => (is => 'ro', isa => Int, required => 1);
  has headers  => (is => 'rw', isa => HashRef, required => 1);

  sub header {
    my ($self, $header) = @_;
    return $self->headers->{ $header };
  }

1;
