package IO::K8s::Api::Extensions::V1beta1::HTTPIngressRuleValue;
  use Moose;

  has 'paths' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Extensions::V1beta1::HTTPIngressPath]'  );
1;
