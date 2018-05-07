package IO::K8s::Api::Core::V1::NodeAddress;
  use Moose;

  has 'address' => (is => 'ro', isa => 'Str'  );
  has 'type' => (is => 'ro', isa => 'Str'  );
1;
