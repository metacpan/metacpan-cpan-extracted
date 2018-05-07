package IO::K8s::Api::Core::V1::ObjectFieldSelector;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'fieldPath' => (is => 'ro', isa => 'Str'  );
1;
