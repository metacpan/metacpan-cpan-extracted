package IO::K8s::Api::Storage::V1alpha1::VolumeError;
  use Moose;
  use IO::K8s;

  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'time' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
