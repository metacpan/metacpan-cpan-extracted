package IO::K8s::Api::Core::V1::NamespaceSpec;
  use Moose;

  has 'finalizers' => (is => 'ro', isa => 'ArrayRef[Str]'  );
1;
