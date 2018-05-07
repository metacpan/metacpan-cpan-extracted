package IO::K8s::Api::Core::V1::ServiceStatus;
  use Moose;

  has 'loadBalancer' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::LoadBalancerStatus'  );
1;
