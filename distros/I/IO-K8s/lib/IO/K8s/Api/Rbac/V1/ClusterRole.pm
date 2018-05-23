package IO::K8s::Api::Rbac::V1::ClusterRole;
  use Moose;
  use IO::K8s;

  has 'aggregationRule' => (is => 'ro', isa => 'IO::K8s::Api::Rbac::V1::AggregationRule'  );
  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'rules' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Rbac::V1::PolicyRule]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
