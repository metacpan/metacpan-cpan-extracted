package IO::K8s::Api::Rbac::V1::PolicyRule;
  use Moose;

  has 'apiGroups' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'nonResourceURLs' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'resourceNames' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'resources' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'verbs' => (is => 'ro', isa => 'ArrayRef[Str]'  );
1;
