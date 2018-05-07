package IO::K8s::Api::Rbac::V1beta1::RoleRef;
  use Moose;

  has 'apiGroup' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
1;
