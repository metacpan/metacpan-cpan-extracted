package IO::K8s::Api::Core::V1::SessionAffinityConfig;
  use Moose;
  use IO::K8s;

  has 'clientIP' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ClientIPConfig'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
