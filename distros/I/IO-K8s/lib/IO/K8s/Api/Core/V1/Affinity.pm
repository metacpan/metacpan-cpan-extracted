package IO::K8s::Api::Core::V1::Affinity;
  use Moose;
  use IO::K8s;

  has 'nodeAffinity' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::NodeAffinity'  );
  has 'podAffinity' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PodAffinity'  );
  has 'podAntiAffinity' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PodAntiAffinity'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
