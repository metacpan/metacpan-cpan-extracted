package IO::K8s::Api::Core::V1::FlockerVolumeSource;
  use Moose;
  use IO::K8s;

  has 'datasetName' => (is => 'ro', isa => 'Str'  );
  has 'datasetUUID' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
