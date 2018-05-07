package IO::K8s::Api::Authorization::V1beta1::SelfSubjectAccessReviewSpec;
  use Moose;

  has 'nonResourceAttributes' => (is => 'ro', isa => 'IO::K8s::Api::Authorization::V1beta1::NonResourceAttributes'  );
  has 'resourceAttributes' => (is => 'ro', isa => 'IO::K8s::Api::Authorization::V1beta1::ResourceAttributes'  );
1;
