package IO::K8s::Api::Core::V1::WeightedPodAffinityTerm;
  use Moose;

  has 'podAffinityTerm' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PodAffinityTerm'  );
  has 'weight' => (is => 'ro', isa => 'Int'  );
1;
