package IO::K8s::Api::Core::V1::PreferredSchedulingTerm;
  use Moose;

  has 'preference' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::NodeSelectorTerm'  );
  has 'weight' => (is => 'ro', isa => 'Int'  );
1;
