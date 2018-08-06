package GCloud::CLIWrapper::Result {
  use Moose;
  has rc => (is => 'ro', isa => 'Int', required => 1);
  has output => (is => 'ro', isa => 'Str');
  has json => (is => 'ro', isa => 'HashRef');
 
  has success => (is => 'ro', isa => 'Bool', lazy => 1, default => sub {
    my $self = shift;
    $self->rc == 0;
  });
}
1;
