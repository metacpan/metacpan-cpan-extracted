package IO::K8s::Api::Core::V1::NFSVolumeSource;
  use Moose;
  use IO::K8s;

  has 'path' => (is => 'ro', isa => 'Str'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'server' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
