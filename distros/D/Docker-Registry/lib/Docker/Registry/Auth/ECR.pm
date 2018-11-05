package Docker::Registry::Auth::ECR;
  use Moo;
  use Types::Standard qw/Str/;
  with 'Docker::Registry::Auth';

  use Paws;

  has region => (is => 'ro', isa => Str);

  has ecr => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    die "Docker::Registry::Auth::ECR needs region" if (not defined $self->region);
    Paws->service('ECR', region => $self->region);
  });

  has token => (is => 'ro', isa => Str, required => 1, lazy => 1, default => sub {
    my $self = shift;
    $self->ecr->GetAuthorizationToken->AuthorizationData->[0]->AuthorizationToken;  
  });

  sub authorize {
    my ($self, $request) = @_;

    $request->header('Authorization', 'Basic ' . $self->token);
    return $request;
  }

1;
