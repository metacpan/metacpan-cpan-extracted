package IO::K8s::Api::Core::V1::Binding;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'target' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ObjectReference'  );
1;
