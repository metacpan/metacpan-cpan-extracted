package IO::K8s::Api::Core::V1::PreferredSchedulingTerm;
  use Moose;
  use IO::K8s;

  has 'preference' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::NodeSelectorTerm'  );
  has 'weight' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
