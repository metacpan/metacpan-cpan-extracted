package IO::K8s::Api::Rbac::V1::ClusterRoleBinding;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'roleRef' => (is => 'ro', isa => 'IO::K8s::Api::Rbac::V1::RoleRef'  );
  has 'subjects' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Rbac::V1::Subject]'  );
1;
