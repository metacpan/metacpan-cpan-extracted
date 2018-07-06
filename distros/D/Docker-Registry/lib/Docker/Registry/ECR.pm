package Docker::Registry::ECR;
  use Moose;
  extends 'Docker::Registry::V2';

  has '+url' => (lazy => 1, default => sub {
    my $self = shift;
    die "Must specify account_id and region in constructor" if (not defined $self->account_id or
                                                                not defined $self->region);
    sprintf 'https://%s.dkr.ecr.%s.amazonaws.com', $self->account_id, $self->region;
  });

  override build_auth => sub {
    my $self = shift;
    require Docker::Registry::Auth::ECR;
    Docker::Registry::Auth::ECR->new(region => $self->region);
  };

  has account_id => (is => 'ro', isa => 'Str');
  has region => (is => 'ro', isa => 'Str');

1;
