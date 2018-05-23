package IO::K8s::Api::Extensions::V1beta1::NetworkPolicyPort;
  use Moose;
  use IO::K8s;

  has 'port' => (is => 'ro', isa => 'Str'  );
  has 'protocol' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
