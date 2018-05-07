package IO::K8s::Api::Core::V1::DownwardAPIVolumeSource;
  use Moose;

  has 'defaultMode' => (is => 'ro', isa => 'Int'  );
  has 'items' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::DownwardAPIVolumeFile]'  );
1;
