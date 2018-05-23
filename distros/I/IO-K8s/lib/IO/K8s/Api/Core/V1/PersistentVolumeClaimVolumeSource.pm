package IO::K8s::Api::Core::V1::PersistentVolumeClaimVolumeSource;
  use Moose;
  use IO::K8s;

  has 'claimName' => (is => 'ro', isa => 'Str'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
