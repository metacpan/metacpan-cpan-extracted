package IO::K8s::Api::Core::V1::DaemonEndpoint;
  use Moose;
  use IO::K8s;

  has 'Port' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
