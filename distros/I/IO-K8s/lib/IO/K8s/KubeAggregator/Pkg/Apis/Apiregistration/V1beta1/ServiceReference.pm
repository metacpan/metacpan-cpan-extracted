package IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::ServiceReference;
  use Moose;
  use IO::K8s;

  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'namespace' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
