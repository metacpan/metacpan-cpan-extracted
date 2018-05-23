package IO::K8s::Api::Extensions::V1beta1::IngressSpec;
  use Moose;
  use IO::K8s;

  has 'backend' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::IngressBackend'  );
  has 'rules' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Extensions::V1beta1::IngressRule]'  );
  has 'tls' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Extensions::V1beta1::IngressTLS]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
