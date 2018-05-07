package IO::K8s::Api::Policy::V1beta1::Eviction;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'deleteOptions' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::DeleteOptions'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
1;
