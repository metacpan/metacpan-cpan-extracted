package IO::K8s::Api::Extensions::V1beta1::ReplicaSet;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'spec' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::ReplicaSetSpec'  );
  has 'status' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::ReplicaSetStatus'  );
1;
