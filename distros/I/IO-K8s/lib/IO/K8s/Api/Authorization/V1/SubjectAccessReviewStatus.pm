package IO::K8s::Api::Authorization::V1::SubjectAccessReviewStatus;
  use Moose;

  has 'allowed' => (is => 'ro', isa => 'Bool'  );
  has 'denied' => (is => 'ro', isa => 'Bool'  );
  has 'evaluationError' => (is => 'ro', isa => 'Str'  );
  has 'reason' => (is => 'ro', isa => 'Str'  );
1;
