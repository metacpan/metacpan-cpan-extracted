package IO::K8s::Api::Apps::V1::RollingUpdateDaemonSet;
  use Moose;
  use IO::K8s;

  has 'maxUnavailable' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
