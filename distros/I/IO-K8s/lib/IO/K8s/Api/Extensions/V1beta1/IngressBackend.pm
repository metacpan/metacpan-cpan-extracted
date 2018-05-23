package IO::K8s::Api::Extensions::V1beta1::IngressBackend;
  use Moose;
  use IO::K8s;

  has 'serviceName' => (is => 'ro', isa => 'Str'  );
  has 'servicePort' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
