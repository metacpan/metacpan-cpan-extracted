package IO::K8s::Api::Core::V1::HostPathVolumeSource;
  use Moose;

  has 'path' => (is => 'ro', isa => 'Str'  );
  has 'type' => (is => 'ro', isa => 'Str'  );
1;
