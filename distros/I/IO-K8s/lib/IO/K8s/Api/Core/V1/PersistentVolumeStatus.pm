package IO::K8s::Api::Core::V1::PersistentVolumeStatus;
  use Moose;

  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'phase' => (is => 'ro', isa => 'Str'  );
  has 'reason' => (is => 'ro', isa => 'Str'  );
1;
