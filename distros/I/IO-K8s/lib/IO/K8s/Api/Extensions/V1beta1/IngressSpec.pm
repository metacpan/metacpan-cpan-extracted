package IO::K8s::Api::Extensions::V1beta1::IngressSpec;
  use Moose;

  has 'backend' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::IngressBackend'  );
  has 'rules' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Extensions::V1beta1::IngressRule]'  );
  has 'tls' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Extensions::V1beta1::IngressTLS]'  );
1;
