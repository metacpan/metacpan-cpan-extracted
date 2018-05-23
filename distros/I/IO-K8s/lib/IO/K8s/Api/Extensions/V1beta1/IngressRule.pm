package IO::K8s::Api::Extensions::V1beta1::IngressRule;
  use Moose;
  use IO::K8s;

  has 'host' => (is => 'ro', isa => 'Str'  );
  has 'http' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::HTTPIngressRuleValue'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
