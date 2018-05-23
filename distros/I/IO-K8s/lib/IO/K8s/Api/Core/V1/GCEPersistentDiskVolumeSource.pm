package IO::K8s::Api::Core::V1::GCEPersistentDiskVolumeSource;
  use Moose;
  use IO::K8s;

  has 'fsType' => (is => 'ro', isa => 'Str'  );
  has 'partition' => (is => 'ro', isa => 'Int'  );
  has 'pdName' => (is => 'ro', isa => 'Str'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
