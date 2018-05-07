package IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::ServiceReference;
  use Moose;

  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'namespace' => (is => 'ro', isa => 'Str'  );
1;
