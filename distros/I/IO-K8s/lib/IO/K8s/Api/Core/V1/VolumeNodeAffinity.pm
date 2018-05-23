package IO::K8s::Api::Core::V1::VolumeNodeAffinity;
  use Moose;
  use IO::K8s;

  has 'required' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::NodeSelector'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
