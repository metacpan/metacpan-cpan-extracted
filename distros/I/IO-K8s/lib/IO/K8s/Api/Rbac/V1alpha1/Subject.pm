package IO::K8s::Api::Rbac::V1alpha1::Subject;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'namespace' => (is => 'ro', isa => 'Str'  );
1;
