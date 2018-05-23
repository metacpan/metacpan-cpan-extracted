package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::OwnerReference;
  use Moose;
  use IO::K8s;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'blockOwnerDeletion' => (is => 'ro', isa => 'Bool'  );
  has 'controller' => (is => 'ro', isa => 'Bool'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'uid' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
