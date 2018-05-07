package IO::K8s::Api::Core::V1::LoadBalancerIngress;
  use Moose;

  has 'hostname' => (is => 'ro', isa => 'Str'  );
  has 'ip' => (is => 'ro', isa => 'Str'  );
1;
