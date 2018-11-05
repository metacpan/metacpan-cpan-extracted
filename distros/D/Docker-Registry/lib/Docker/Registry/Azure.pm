package Docker::Registry::Azure;
  use Moo;
  use Types::Standard qw/Str/;

  extends 'Docker::Registry::V2';

  has '+url' => (lazy => 1, default => sub {
    my $self = shift;
    die "Must specify name" if (not defined $self->name);
    sprintf 'https://%s.azurecr.io', $self->name;
  });

  around build_auth => sub {
    my ($orig, $self) = @_;
    if (defined $self->password) {
      # We're using the "Admin Account" mode
      # https://docs.microsoft.com/en-us/azure/container-registry/container-registry-authentication#admin-account
      require Docker::Registry::Auth::Basic;
      Docker::Registry::Auth::Basic->new(
        username => $self->name,
        password => $self->password,
      );
    } else {
      # We're using Service Principal mode
      require Docker::Registry::Auth::AzureServicePrincipal;
      Docker::Registry::Auth::AzureServicePrincipal->new;
    }
  };

  has name => (is => 'ro', isa => Str);
  has password => (is => 'ro', isa => Str);

1;
