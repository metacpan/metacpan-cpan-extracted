package IO::K8s::Api::Rbac::V1beta1::AggregationRule;
  use Moose;
  use IO::K8s;

  has 'clusterRoleSelectors' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
