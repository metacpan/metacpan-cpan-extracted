package IO::K8s::Api::Core::V1::AzureDiskVolumeSource;
  use Moose;

  has 'cachingMode' => (is => 'ro', isa => 'Str'  );
  has 'diskName' => (is => 'ro', isa => 'Str'  );
  has 'diskURI' => (is => 'ro', isa => 'Str'  );
  has 'fsType' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
1;
