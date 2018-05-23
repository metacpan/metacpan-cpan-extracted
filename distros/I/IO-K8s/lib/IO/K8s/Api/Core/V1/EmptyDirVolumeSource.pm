package IO::K8s::Api::Core::V1::EmptyDirVolumeSource;
  use Moose;
  use IO::K8s;

  has 'medium' => (is => 'ro', isa => 'Str'  );
  has 'sizeLimit' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
