package Kubernetes::REST::CallContext;
  use Moo;
  use Types::Standard qw/Str ArrayRef InstanceOf/;

  has method => (is => 'ro', isa => Str, required => 1);
  has params => (is => 'ro', isa => ArrayRef, required => 1);
  has credentials => (is => 'ro', required => 1);
  has server => (is => 'ro', isa => InstanceOf['Kubernetes::REST::Server'], required => 1);

1;
