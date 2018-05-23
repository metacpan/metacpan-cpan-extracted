package IO::K8s::Api::Apps::V1::Deployment;
  use Moose;
  use IO::K8s;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'spec' => (is => 'ro', isa => 'IO::K8s::Api::Apps::V1::DeploymentSpec'  );
  has 'status' => (is => 'ro', isa => 'IO::K8s::Api::Apps::V1::DeploymentStatus'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
