package IO::K8s::Api::Apps::V1beta2::Deployment;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'spec' => (is => 'ro', isa => 'IO::K8s::Api::Apps::V1beta2::DeploymentSpec'  );
  has 'status' => (is => 'ro', isa => 'IO::K8s::Api::Apps::V1beta2::DeploymentStatus'  );
1;
