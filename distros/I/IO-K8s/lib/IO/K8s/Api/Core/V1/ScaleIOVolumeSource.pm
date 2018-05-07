package IO::K8s::Api::Core::V1::ScaleIOVolumeSource;
  use Moose;

  has 'fsType' => (is => 'ro', isa => 'Str'  );
  has 'gateway' => (is => 'ro', isa => 'Str'  );
  has 'protectionDomain' => (is => 'ro', isa => 'Str'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'secretRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::LocalObjectReference'  );
  has 'sslEnabled' => (is => 'ro', isa => 'Bool'  );
  has 'storageMode' => (is => 'ro', isa => 'Str'  );
  has 'storagePool' => (is => 'ro', isa => 'Str'  );
  has 'system' => (is => 'ro', isa => 'Str'  );
  has 'volumeName' => (is => 'ro', isa => 'Str'  );
1;
