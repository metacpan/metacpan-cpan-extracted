package IO::K8s::Api::Core::V1::ResourceFieldSelector;
  use Moose;

  has 'containerName' => (is => 'ro', isa => 'Str'  );
  has 'divisor' => (is => 'ro', isa => 'Str'  );
  has 'resource' => (is => 'ro', isa => 'Str'  );
1;
