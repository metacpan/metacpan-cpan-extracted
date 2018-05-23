package IO::K8s::Api::Extensions::V1beta1::HTTPIngressPath;
  use Moose;
  use IO::K8s;

  has 'backend' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::IngressBackend'  );
  has 'path' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
