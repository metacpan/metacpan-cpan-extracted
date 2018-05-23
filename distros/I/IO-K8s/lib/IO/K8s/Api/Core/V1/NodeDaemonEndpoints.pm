package IO::K8s::Api::Core::V1::NodeDaemonEndpoints;
  use Moose;
  use IO::K8s;

  has 'kubeletEndpoint' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::DaemonEndpoint'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
