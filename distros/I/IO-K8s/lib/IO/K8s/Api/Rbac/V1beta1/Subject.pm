package IO::K8s::Api::Rbac::V1beta1::Subject;
  use Moose;
  use IO::K8s;

  has 'apiGroup' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'namespace' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
