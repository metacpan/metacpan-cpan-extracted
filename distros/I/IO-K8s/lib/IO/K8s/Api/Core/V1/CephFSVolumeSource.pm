package IO::K8s::Api::Core::V1::CephFSVolumeSource;
  use Moose;

  has 'monitors' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'path' => (is => 'ro', isa => 'Str'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'secretFile' => (is => 'ro', isa => 'Str'  );
  has 'secretRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::LocalObjectReference'  );
  has 'user' => (is => 'ro', isa => 'Str'  );
1;
