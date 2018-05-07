package IO::K8s::Api::Core::V1::NodeSelector;
  use Moose;

  has 'nodeSelectorTerms' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::NodeSelectorTerm]'  );
1;
