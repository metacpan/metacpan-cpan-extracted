package Kubernetes::REST::Error;
  use Moo;
  use Types::Standard qw/Str/;
  extends 'Throwable::Error';

  has type => (is => 'ro', isa => Str, required => 1);
  has detail => (is => 'ro');

  sub header {
    my $self = shift;
    return sprintf "Exception with type: %s: %s", $self->type, $self->message;
  }

  sub as_string {
    my $self = shift;
    if (defined $self->detail) {
      return sprintf "%s\nDetail: %s", $self->header, $self->detail;
    } else {
      return $self->header;
    }
  }

package Kubernetes::REST::RemoteError;
  use Moo;
  use Types::Standard qw/Int/;
  extends 'Kubernetes::REST::Error';

  has '+type' => (default => sub { 'Remote' });
  has status => (is => 'ro', isa => Int, required => 1);

  around header => sub {
    my ($orig, $self) = @_;
    my $orig_message = $self->$orig;
    sprintf "%s with HTTP status %d", $orig_message, $self->status;
  };

1;
