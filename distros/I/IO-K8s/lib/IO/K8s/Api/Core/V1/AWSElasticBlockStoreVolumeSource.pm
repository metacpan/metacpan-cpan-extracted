package IO::K8s::Api::Core::V1::AWSElasticBlockStoreVolumeSource;
  use Moose;

  has 'fsType' => (is => 'ro', isa => 'Str'  );
  has 'partition' => (is => 'ro', isa => 'Int'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'volumeID' => (is => 'ro', isa => 'Str'  );
1;
