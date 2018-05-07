package IO::K8s::Api::Authorization::V1::SubjectAccessReviewSpec;
  use Moose;

  has 'extra' => (is => 'ro', isa => 'HashRef[ArrayRef[Str]]'  );
  has 'groups' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'nonResourceAttributes' => (is => 'ro', isa => 'IO::K8s::Api::Authorization::V1::NonResourceAttributes'  );
  has 'resourceAttributes' => (is => 'ro', isa => 'IO::K8s::Api::Authorization::V1::ResourceAttributes'  );
  has 'uid' => (is => 'ro', isa => 'Str'  );
  has 'user' => (is => 'ro', isa => 'Str'  );
1;
