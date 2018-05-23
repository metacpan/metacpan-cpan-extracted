package IO::K8s::Api::Core::V1::FCVolumeSource;
  use Moose;
  use IO::K8s;

  has 'fsType' => (is => 'ro', isa => 'Str'  );
  has 'lun' => (is => 'ro', isa => 'Int'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'targetWWNs' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'wwids' => (is => 'ro', isa => 'ArrayRef[Str]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
