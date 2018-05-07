package IO::K8s::Api::Core::V1::FlockerVolumeSource;
  use Moose;

  has 'datasetName' => (is => 'ro', isa => 'Str'  );
  has 'datasetUUID' => (is => 'ro', isa => 'Str'  );
1;
