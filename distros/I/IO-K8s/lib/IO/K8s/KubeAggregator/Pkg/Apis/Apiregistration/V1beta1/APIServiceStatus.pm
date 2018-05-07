package IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIServiceStatus;
  use Moose;

  has 'conditions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIServiceCondition]'  );
1;
