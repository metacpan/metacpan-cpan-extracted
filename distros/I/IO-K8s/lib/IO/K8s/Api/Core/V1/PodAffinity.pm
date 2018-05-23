package IO::K8s::Api::Core::V1::PodAffinity;
  use Moose;
  use IO::K8s;

  has 'preferredDuringSchedulingIgnoredDuringExecution' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::WeightedPodAffinityTerm]'  );
  has 'requiredDuringSchedulingIgnoredDuringExecution' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::PodAffinityTerm]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
