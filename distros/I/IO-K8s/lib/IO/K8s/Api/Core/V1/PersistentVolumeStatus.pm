package IO::K8s::Api::Core::V1::PersistentVolumeStatus;
  use Moose;
  use IO::K8s;

  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'phase' => (is => 'ro', isa => 'Str'  );
  has 'reason' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
