package IO::K8s::Api::Extensions::V1beta1::HTTPIngressRuleValue;
  use Moose;
  use IO::K8s;

  has 'paths' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Extensions::V1beta1::HTTPIngressPath]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
