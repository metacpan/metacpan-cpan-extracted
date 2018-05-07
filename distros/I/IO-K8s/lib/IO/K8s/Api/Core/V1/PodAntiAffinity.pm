package IO::K8s::Api::Core::V1::PodAntiAffinity;
  use Moose;

  has 'preferredDuringSchedulingIgnoredDuringExecution' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::WeightedPodAffinityTerm]'  );
  has 'requiredDuringSchedulingIgnoredDuringExecution' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::PodAffinityTerm]'  );
1;
