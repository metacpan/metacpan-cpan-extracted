package IO::K8s::Api::Core::V1::NodeSelectorTerm;
  use Moose;
  use IO::K8s;

  has 'matchExpressions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::NodeSelectorRequirement]'  );
  has 'matchFields' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::NodeSelectorRequirement]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
