package IO::K8s::Api::Core::V1::AWSElasticBlockStoreVolumeSource;
  use Moose;
  use IO::K8s;

  has 'fsType' => (is => 'ro', isa => 'Str'  );
  has 'partition' => (is => 'ro', isa => 'Int'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'volumeID' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
