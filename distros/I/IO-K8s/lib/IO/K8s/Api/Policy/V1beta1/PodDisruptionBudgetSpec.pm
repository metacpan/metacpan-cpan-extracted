package IO::K8s::Api::Policy::V1beta1::PodDisruptionBudgetSpec;
  use Moose;
  use IO::K8s;

  has 'maxUnavailable' => (is => 'ro', isa => 'Str'  );
  has 'minAvailable' => (is => 'ro', isa => 'Str'  );
  has 'selector' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
