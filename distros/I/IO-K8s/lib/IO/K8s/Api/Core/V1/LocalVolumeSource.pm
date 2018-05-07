package IO::K8s::Api::Core::V1::LocalVolumeSource;
  use Moose;

  has 'path' => (is => 'ro', isa => 'Str'  );
1;
