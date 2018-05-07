package IO::K8s::Api::Core::V1::EmptyDirVolumeSource;
  use Moose;

  has 'medium' => (is => 'ro', isa => 'Str'  );
  has 'sizeLimit' => (is => 'ro', isa => 'Str'  );
1;
