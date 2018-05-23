package IO::K8s::Api::Authorization::V1::SubjectAccessReviewStatus;
  use Moose;
  use IO::K8s;

  has 'allowed' => (is => 'ro', isa => 'Bool'  );
  has 'denied' => (is => 'ro', isa => 'Bool'  );
  has 'evaluationError' => (is => 'ro', isa => 'Str'  );
  has 'reason' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
