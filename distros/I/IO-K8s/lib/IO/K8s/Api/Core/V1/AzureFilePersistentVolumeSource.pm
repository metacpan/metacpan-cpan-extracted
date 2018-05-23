package IO::K8s::Api::Core::V1::AzureFilePersistentVolumeSource;
  use Moose;
  use IO::K8s;

  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'secretName' => (is => 'ro', isa => 'Str'  );
  has 'secretNamespace' => (is => 'ro', isa => 'Str'  );
  has 'shareName' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
