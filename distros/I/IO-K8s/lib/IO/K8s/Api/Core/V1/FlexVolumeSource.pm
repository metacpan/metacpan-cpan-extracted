package IO::K8s::Api::Core::V1::FlexVolumeSource;
  use Moose;

  has 'driver' => (is => 'ro', isa => 'Str'  );
  has 'fsType' => (is => 'ro', isa => 'Str'  );
  has 'options' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'secretRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::LocalObjectReference'  );
1;
