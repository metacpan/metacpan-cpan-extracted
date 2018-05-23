package IO::K8s::Api::Core::V1::DownwardAPIProjection;
  use Moose;
  use IO::K8s;

  has 'items' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::DownwardAPIVolumeFile]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
