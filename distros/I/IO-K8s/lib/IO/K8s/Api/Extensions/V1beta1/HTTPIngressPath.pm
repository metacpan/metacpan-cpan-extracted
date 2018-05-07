package IO::K8s::Api::Extensions::V1beta1::HTTPIngressPath;
  use Moose;

  has 'backend' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::IngressBackend'  );
  has 'path' => (is => 'ro', isa => 'Str'  );
1;
