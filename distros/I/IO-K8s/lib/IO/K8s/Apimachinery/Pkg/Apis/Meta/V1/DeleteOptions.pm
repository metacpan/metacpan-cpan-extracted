package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::DeleteOptions;
  use Moose;
  use IO::K8s;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'gracePeriodSeconds' => (is => 'ro', isa => 'Int'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'orphanDependents' => (is => 'ro', isa => 'Bool'  );
  has 'preconditions' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Preconditions'  );
  has 'propagationPolicy' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
