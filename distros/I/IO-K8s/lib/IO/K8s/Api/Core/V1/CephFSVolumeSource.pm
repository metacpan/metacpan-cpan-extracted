package IO::K8s::Api::Core::V1::CephFSVolumeSource;
  use Moose;
  use IO::K8s;

  has 'monitors' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'path' => (is => 'ro', isa => 'Str'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'secretFile' => (is => 'ro', isa => 'Str'  );
  has 'secretRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::LocalObjectReference'  );
  has 'user' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
