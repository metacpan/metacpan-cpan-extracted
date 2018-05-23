package Docker::Registry::Request;
  use Moose;

  has headers => (is => 'ro', isa => 'HTTP::Headers', default => sub { HTTP::Headers->new });
  has method => (is => 'ro', isa => 'Str', required => 1);
  has url => (is => 'ro', isa => 'Str', required => 1);
  has content => (is => 'ro', isa => 'Maybe[Str]');

  sub header_hash {
    my $self = shift;
    my $headers = {};
    $self->headers->scan(sub { $headers->{ $_[0] } = $_[1] });
    return $headers;
  }

  sub header {
    my ($self, $header, $value) = @_;
    $self->headers->header($header, $value) if (defined $value);
    return $self->headers->header($header);
  }

1;
