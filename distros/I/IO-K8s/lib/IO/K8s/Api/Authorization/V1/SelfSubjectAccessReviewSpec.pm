package IO::K8s::Api::Authorization::V1::SelfSubjectAccessReviewSpec;
  use Moose;
  use IO::K8s;

  has 'nonResourceAttributes' => (is => 'ro', isa => 'IO::K8s::Api::Authorization::V1::NonResourceAttributes'  );
  has 'resourceAttributes' => (is => 'ro', isa => 'IO::K8s::Api::Authorization::V1::ResourceAttributes'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
