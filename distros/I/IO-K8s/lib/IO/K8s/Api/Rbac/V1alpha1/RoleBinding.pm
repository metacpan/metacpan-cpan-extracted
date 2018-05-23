package IO::K8s::Api::Rbac::V1alpha1::RoleBinding;
  use Moose;
  use IO::K8s;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'roleRef' => (is => 'ro', isa => 'IO::K8s::Api::Rbac::V1alpha1::RoleRef'  );
  has 'subjects' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Rbac::V1alpha1::Subject]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
