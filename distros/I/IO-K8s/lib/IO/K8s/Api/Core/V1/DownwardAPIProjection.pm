package IO::K8s::Api::Core::V1::DownwardAPIProjection;
  use Moose;

  has 'items' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::DownwardAPIVolumeFile]'  );
1;
