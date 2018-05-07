package IO::K8s::Api::Core::V1::PersistentVolumeClaimVolumeSource;
  use Moose;

  has 'claimName' => (is => 'ro', isa => 'Str'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
1;
