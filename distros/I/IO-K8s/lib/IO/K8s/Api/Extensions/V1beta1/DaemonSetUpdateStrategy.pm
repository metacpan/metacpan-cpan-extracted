package IO::K8s::Api::Extensions::V1beta1::DaemonSetUpdateStrategy;
  use Moose;
  use IO::K8s;

  has 'rollingUpdate' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::RollingUpdateDaemonSet'  );
  has 'type' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
