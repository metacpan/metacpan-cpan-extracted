package IO::K8s::Api::Extensions::V1beta1::IPBlock;
  use Moose;

  has 'cidr' => (is => 'ro', isa => 'Str'  );
  has 'except' => (is => 'ro', isa => 'ArrayRef[Str]'  );
1;
