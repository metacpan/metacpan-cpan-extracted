package IO::K8s::Api::Core::V1::NodeDaemonEndpoints;
  use Moose;

  has 'kubeletEndpoint' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::DaemonEndpoint'  );
1;
