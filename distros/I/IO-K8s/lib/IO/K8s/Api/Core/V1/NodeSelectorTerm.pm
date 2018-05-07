package IO::K8s::Api::Core::V1::NodeSelectorTerm;
  use Moose;

  has 'matchExpressions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::NodeSelectorRequirement]'  );
  has 'matchFields' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::NodeSelectorRequirement]'  );
1;
