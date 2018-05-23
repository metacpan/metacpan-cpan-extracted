package IO::K8s::Api::Extensions::V1beta1::IngressTLS;
  use Moose;
  use IO::K8s;

  has 'hosts' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'secretName' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
