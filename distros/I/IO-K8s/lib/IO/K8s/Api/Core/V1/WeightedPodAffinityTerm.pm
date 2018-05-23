package IO::K8s::Api::Core::V1::WeightedPodAffinityTerm;
  use Moose;
  use IO::K8s;

  has 'podAffinityTerm' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PodAffinityTerm'  );
  has 'weight' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
