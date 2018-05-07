package IO::K8s::Api::Authorization::V1::ResourceRule;
  use Moose;

  has 'apiGroups' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'resourceNames' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'resources' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'verbs' => (is => 'ro', isa => 'ArrayRef[Str]'  );
1;
