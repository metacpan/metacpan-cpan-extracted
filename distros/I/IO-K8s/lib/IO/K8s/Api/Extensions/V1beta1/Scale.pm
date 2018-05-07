package IO::K8s::Api::Extensions::V1beta1::Scale;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'spec' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::ScaleSpec'  );
  has 'status' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::ScaleStatus'  );
1;
