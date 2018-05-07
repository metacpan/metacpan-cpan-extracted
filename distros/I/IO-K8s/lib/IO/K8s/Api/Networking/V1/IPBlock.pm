package IO::K8s::Api::Networking::V1::IPBlock;
  use Moose;

  has 'cidr' => (is => 'ro', isa => 'Str'  );
  has 'except' => (is => 'ro', isa => 'ArrayRef[Str]'  );
1;
