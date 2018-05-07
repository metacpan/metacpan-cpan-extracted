package IO::K8s::Api::Rbac::V1alpha1::AggregationRule;
  use Moose;

  has 'clusterRoleSelectors' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector]'  );
1;
