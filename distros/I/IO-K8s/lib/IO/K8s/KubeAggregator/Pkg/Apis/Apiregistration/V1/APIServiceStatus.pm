package IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIServiceStatus;
  use Moose;
  use IO::K8s;

  has 'conditions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIServiceCondition]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
