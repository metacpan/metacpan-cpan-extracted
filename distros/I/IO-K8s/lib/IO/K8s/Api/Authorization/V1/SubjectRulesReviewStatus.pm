package IO::K8s::Api::Authorization::V1::SubjectRulesReviewStatus;
  use Moose;

  has 'evaluationError' => (is => 'ro', isa => 'Str'  );
  has 'incomplete' => (is => 'ro', isa => 'Bool'  );
  has 'nonResourceRules' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Authorization::V1::NonResourceRule]'  );
  has 'resourceRules' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Authorization::V1::ResourceRule]'  );
1;
