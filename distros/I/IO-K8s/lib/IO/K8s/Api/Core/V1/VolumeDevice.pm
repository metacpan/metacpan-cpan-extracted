package IO::K8s::Api::Core::V1::VolumeDevice;
  use Moose;

  has 'devicePath' => (is => 'ro', isa => 'Str'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
1;
