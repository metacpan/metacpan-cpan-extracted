package Docker::Registry::Auth::AzureServicePrincipal;
  use Moo;
  with 'Docker::Registry::Auth';
  use JSON::MaybeXS;

  use Azure::AD::ClientCredentials;
  has ad_auth => (
    is => 'ro',
    default => sub {
      Azure::AD::ClientCredentials->new(
        resource_id => "https://management.core.windows.net/",       
      );
    }
  );

  has ua => (is => 'ro', default => sub { HTTP::Tiny->new(timeout => 20) });

  sub authorize {
    my ($self, $request, $scope) = @_;

    my ($login_server) = ($request->url =~ m|//(.*?)/v2|);
    die "Can't detect login_server from " . $request->url if (not defined $login_server);

    my $challenge = $self->ua->get("https://$login_server/v2/");
    die "Registry didn't issue a challenge" if ($challenge->{ status } != 401);
    die "Registry didn't issue a challenge" if (not defined $challenge->{ headers }->{ 'www-authenticate' });

    my $authenticate = $challenge->{ headers }->{ 'www-authenticate' };
    my @tokens = split / /, $authenticate, 2;
    die "Registry doesn't support AAD login" if (@tokens < 2 or lc($tokens[0]) ne 'bearer');
    
    my %params = map { my @kv = split /=/, $_; $kv[1] =~ s/"//g; ($kv[0] => $kv[1])  } split /,/, $tokens[1];
    if (not defined $params{ realm } or not defined $params{ service }) {
      die "Registry doesn't support AAD login"
    }

    my $authhost = $params{ realm };
    $authhost =~ s|/oauth2/token|/oauth2/exchange|;

    my $response = $self->ua->post_form(
      $authhost,
      {
        grant_type => 'access_token',
        service => $params{ service },
        tenant => $self->ad_auth->tenant_id,
        access_token => $self->ad_auth->access_token
      }
    );

    die "Access to registry was denied. Response code: $response->{ status }" if (not $response->{ success });

    my $refresh_token = decode_json($response->{ content })->{ refresh_token };

    $response = $self->ua->post_form(
      $params{ realm },
      {
        grant_type => 'refresh_token',
        service => $params{ service },
        scope => $scope,
        refresh_token => $refresh_token,
      }
    );

    my $access_token = decode_json($response->{ content })->{ access_token };

    $request->header('Authorization', 'Bearer ' . $access_token);

    return $request;
  }

1;
