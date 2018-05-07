package IO::K8s::Api::Core::V1::NamespaceStatus;
  use Moose;

  has 'phase' => (is => 'ro', isa => 'Str'  );
1;
