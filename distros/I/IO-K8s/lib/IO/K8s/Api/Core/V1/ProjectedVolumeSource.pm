package IO::K8s::Api::Core::V1::ProjectedVolumeSource;
  use Moose;
  use IO::K8s;

  has 'defaultMode' => (is => 'ro', isa => 'Int'  );
  has 'sources' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::VolumeProjection]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
