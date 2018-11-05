package Docker::Registry::Auth::Basic;
  use Moo;
  use Types::Standard qw/Str/;
  with 'Docker::Registry::Auth';

  use MIME::Base64 qw/encode_base64/;

  has username => (is => 'ro', isa => Str, required => 1);
  has password => (is => 'ro', isa => Str, required => 1);

  sub authorize {
    my ($self, $request) = @_;

    my $auth_header = "Basic " . encode_base64(sprintf("%s:%s", $self->username, $self->password), '');
    $request->header('Authorization', $auth_header);

    return $request;
  }

1;
