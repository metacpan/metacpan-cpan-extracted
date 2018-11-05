package Docker::Registry::Auth::GCEServiceAccount;
  use Moo;
  use Types::Standard qw/HashRef Str ArrayRef CodeRef Int/;
  with 'Docker::Registry::Auth';

  use Crypt::JWT qw/encode_jwt/;
  use JSON::MaybeXS;
  use Path::Class;
  use URI;
  use HTTP::Tiny;

  has service_account_file => (is => 'ro', isa => Str, default => sub {
    "$ENV{HOME}/.gcloud/sd.json"
  });

  has service_account => (is => 'ro', isa => HashRef, lazy => 1, default => sub {
    my $self = shift;
    my $f = Path::Class::File->new($self->service_account_file);
    my $json = JSON::MaybeXS->new;
    return $json->decode(join '', $f->slurp);
  });

  has client_email => (is => 'ro', isa => Str, lazy => 1, default => sub {
    my $self = shift;
    my $value = $self->service_account->{ client_email };
    Docker::Registry::Auth::Exception->throw({
      message => "client_email entry not found in service_account information",
    }) if (not defined $value);
    return $value;
  });
  has private_key => (is => 'ro', isa => Str, lazy => 1, default => sub {
    my $self = shift;
    my $value = $self->service_account->{ private_key };
    Docker::Registry::Auth::Exception->throw({
      message => "private_key entry not found in service_account information",
    }) if (not defined $value);
    return $value;
  });

  has scopes => (is => 'ro', isa => ArrayRef[Str], default => sub {
    [ 'https://www.googleapis.com/auth/devstorage.read_only' ];
  });

  has time_source => (is => 'ro', isa => CodeRef, default => sub {
    return sub { time };
  });

  has expiry => (is => 'ro', isa => Int, default => 300);

  has signed_jwt => (is => 'ro', isa => Str, lazy => 1, default => sub {
    my $self = shift;
    my $scope = join ' ', @{ $self->scopes };

    my $time = $self->time_source->();
    my $key = $self->private_key;

    return encode_jwt(
      payload => {
        iss => $self->client_email,
        scope => $scope,
        aud => $self->auth_url,
        iat => $time,
        exp => $time + $self->expiry,
      },
      alg => 'RS256',
      key => \$key,
    );
  });

  has auth_url => (is => 'ro', isa => Str, default => sub {
    'https://www.googleapis.com/oauth2/v4/token';
  });

  has accesstoken => (is => 'ro', isa => Str, lazy => 1, default => sub {
    my $self = shift;

    my $url = URI->new($self->auth_url);
    $url->query_form({
      grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion => $self->signed_jwt,
    });
    my $ua = HTTP::Tiny->new;
    my $result = $ua->request(
      'POST',
      $self->auth_url,
      { headers => {
          'Content-Type' => 'application/x-www-form-urlencoded'
        },
        content => $url->query
      }
    );
    if (not $result->{ success }) {
      $self->handle_error($result);
    } else {
      my $result = $self->handle_success($result); 
      return $result->{ access_token };
    }
  });

  sub handle_success {
    my ($self, $result) = @_;
    my $json = eval { decode_json($result->{ content }) };
    if (not $json) {
      Docker::Registry::Auth::Exception->throw({
        message => "Couldn't json-parse $result->{ content }"
      });
    } else {
      return $json;
    }
  }
  sub handle_error {
    my ($self, $result) = @_;

    my $json = eval { decode_json($result->{ content }) };
    if (not $json) {
      Docker::Registry::Auth::Exception::HTTP->throw({
        status => $result->{ status },
        message => $result->{ content }
      });
    } else {
      Docker::Registry::Auth::Exception::FromRemote->throw({
        status => $result->{ status },
        message => $json->{ error_description } // 'no_error_description',
        code => $json->{ error } // 'no_error_code',
      });
    }
  }

  sub authorize {
    my ($self, $request) = @_;

    $request->header('Authorization', 'Bearer ' . $self->accesstoken);
    return $request;
  }

1;
