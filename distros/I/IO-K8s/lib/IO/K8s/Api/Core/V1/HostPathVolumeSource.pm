package IO::K8s::Api::Core::V1::HostPathVolumeSource;
  use Moose;
  use IO::K8s;

  has 'path' => (is => 'ro', isa => 'Str'  );
  has 'type' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
