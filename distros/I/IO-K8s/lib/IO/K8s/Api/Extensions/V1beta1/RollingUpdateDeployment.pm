package IO::K8s::Api::Extensions::V1beta1::RollingUpdateDeployment;
  use Moose;
  use IO::K8s;

  has 'maxSurge' => (is => 'ro', isa => 'Str'  );
  has 'maxUnavailable' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
