package IO::K8s::Api::Core::V1::FlexPersistentVolumeSource;
  use Moose;
  use IO::K8s;

  has 'driver' => (is => 'ro', isa => 'Str'  );
  has 'fsType' => (is => 'ro', isa => 'Str'  );
  has 'options' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'secretRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::SecretReference'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
