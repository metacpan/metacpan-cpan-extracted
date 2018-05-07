package IO::K8s::Api::Core::V1::Affinity;
  use Moose;

  has 'nodeAffinity' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::NodeAffinity'  );
  has 'podAffinity' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PodAffinity'  );
  has 'podAntiAffinity' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PodAntiAffinity'  );
1;
