package IO::K8s::Api::Core::V1::GCEPersistentDiskVolumeSource;
  use Moose;

  has 'fsType' => (is => 'ro', isa => 'Str'  );
  has 'partition' => (is => 'ro', isa => 'Int'  );
  has 'pdName' => (is => 'ro', isa => 'Str'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
1;
