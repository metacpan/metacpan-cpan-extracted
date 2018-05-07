package IO::K8s::Api::Core::V1::NFSVolumeSource;
  use Moose;

  has 'path' => (is => 'ro', isa => 'Str'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'server' => (is => 'ro', isa => 'Str'  );
1;
