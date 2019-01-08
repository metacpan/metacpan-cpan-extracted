package KubeBuilder::Group;
  use Moose;

  has name => (is => 'ro', isa => 'Str', required => 1);
  has methods => (is => 'ro', isa => 'ArrayRef[KubeBuilder::Method]', required => 1);

  # method_list only contains one method for each
  has method_list => (is => 'ro', isa => 'ArrayRef[KubeBuilder::Method]', lazy => 1, default => sub {
    my $self = shift;
    my %methods = ();
    foreach my $method (@{ $self->methods }) {
      $methods{ $method->call_classname } = $method;
    }
    return [ map { $methods{ $_ } } sort keys %methods ];
  });

1;
