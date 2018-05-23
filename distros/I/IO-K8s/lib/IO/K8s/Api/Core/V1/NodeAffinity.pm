package IO::K8s::Api::Core::V1::NodeAffinity;
  use Moose;
  use IO::K8s;

  has 'preferredDuringSchedulingIgnoredDuringExecution' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::PreferredSchedulingTerm]'  );
  has 'requiredDuringSchedulingIgnoredDuringExecution' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::NodeSelector'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
