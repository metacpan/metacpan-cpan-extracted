package IO::K8s::Api::Admissionregistration::V1beta1::RuleWithOperations;
  use Moose;

  has 'apiGroups' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'apiVersions' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'operations' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'resources' => (is => 'ro', isa => 'ArrayRef[Str]'  );
1;
