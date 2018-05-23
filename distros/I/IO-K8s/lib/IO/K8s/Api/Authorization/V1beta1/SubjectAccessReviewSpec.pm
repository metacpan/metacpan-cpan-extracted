package IO::K8s::Api::Authorization::V1beta1::SubjectAccessReviewSpec;
  use Moose;
  use IO::K8s;

  has 'extra' => (is => 'ro', isa => 'HashRef[ArrayRef[Str]]'  );
  has 'group' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'nonResourceAttributes' => (is => 'ro', isa => 'IO::K8s::Api::Authorization::V1beta1::NonResourceAttributes'  );
  has 'resourceAttributes' => (is => 'ro', isa => 'IO::K8s::Api::Authorization::V1beta1::ResourceAttributes'  );
  has 'uid' => (is => 'ro', isa => 'Str'  );
  has 'user' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
