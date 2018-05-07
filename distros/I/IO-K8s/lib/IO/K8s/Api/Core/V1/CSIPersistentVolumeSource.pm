package IO::K8s::Api::Core::V1::CSIPersistentVolumeSource;
  use Moose;

  has 'controllerPublishSecretRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::SecretReference'  );
  has 'driver' => (is => 'ro', isa => 'Str'  );
  has 'fsType' => (is => 'ro', isa => 'Str'  );
  has 'nodePublishSecretRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::SecretReference'  );
  has 'nodeStageSecretRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::SecretReference'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'volumeAttributes' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'volumeHandle' => (is => 'ro', isa => 'Str'  );
1;
