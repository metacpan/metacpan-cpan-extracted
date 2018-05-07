package IO::K8s::Api::Core::V1::ProjectedVolumeSource;
  use Moose;

  has 'defaultMode' => (is => 'ro', isa => 'Int'  );
  has 'sources' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::VolumeProjection]'  );
1;
