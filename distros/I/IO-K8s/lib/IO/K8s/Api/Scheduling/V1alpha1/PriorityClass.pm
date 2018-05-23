package IO::K8s::Api::Scheduling::V1alpha1::PriorityClass;
  use Moose;
  use IO::K8s;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'description' => (is => 'ro', isa => 'Str'  );
  has 'globalDefault' => (is => 'ro', isa => 'Bool'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'value' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
