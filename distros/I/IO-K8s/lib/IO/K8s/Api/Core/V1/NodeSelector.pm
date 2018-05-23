package IO::K8s::Api::Core::V1::NodeSelector;
  use Moose;
  use IO::K8s;

  has 'nodeSelectorTerms' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::NodeSelectorTerm]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
