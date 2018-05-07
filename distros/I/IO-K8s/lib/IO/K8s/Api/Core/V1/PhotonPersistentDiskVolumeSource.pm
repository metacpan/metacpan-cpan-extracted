package IO::K8s::Api::Core::V1::PhotonPersistentDiskVolumeSource;
  use Moose;

  has 'fsType' => (is => 'ro', isa => 'Str'  );
  has 'pdID' => (is => 'ro', isa => 'Str'  );
1;
