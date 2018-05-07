package IO::K8s::Api::Core::V1::StorageOSVolumeSource;
  use Moose;

  has 'fsType' => (is => 'ro', isa => 'Str'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'secretRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::LocalObjectReference'  );
  has 'volumeName' => (is => 'ro', isa => 'Str'  );
  has 'volumeNamespace' => (is => 'ro', isa => 'Str'  );
1;
