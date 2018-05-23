package IO::K8s::Api::Core::V1::DownwardAPIVolumeSource;
  use Moose;
  use IO::K8s;

  has 'defaultMode' => (is => 'ro', isa => 'Int'  );
  has 'items' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::DownwardAPIVolumeFile]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
