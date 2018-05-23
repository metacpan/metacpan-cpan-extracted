package IO::K8s::Api::Authorization::V1::SelfSubjectAccessReview;
  use Moose;
  use IO::K8s;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'spec' => (is => 'ro', isa => 'IO::K8s::Api::Authorization::V1::SelfSubjectAccessReviewSpec'  );
  has 'status' => (is => 'ro', isa => 'IO::K8s::Api::Authorization::V1::SubjectAccessReviewStatus'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
