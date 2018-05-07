package IO::K8s::Api::Extensions::V1beta1::IngressRule;
  use Moose;

  has 'host' => (is => 'ro', isa => 'Str'  );
  has 'http' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::HTTPIngressRuleValue'  );
1;
