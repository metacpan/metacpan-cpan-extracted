package IO::K8s::Api::Core::V1::VsphereVirtualDiskVolumeSource;
  use Moose;
  use IO::K8s;

  has 'fsType' => (is => 'ro', isa => 'Str'  );
  has 'storagePolicyID' => (is => 'ro', isa => 'Str'  );
  has 'storagePolicyName' => (is => 'ro', isa => 'Str'  );
  has 'volumePath' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
