package IO::K8s::Api::Storage::V1alpha1::VolumeError;
  use Moose;

  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'time' => (is => 'ro', isa => 'Str'  );
1;
