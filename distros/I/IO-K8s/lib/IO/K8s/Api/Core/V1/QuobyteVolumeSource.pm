package IO::K8s::Api::Core::V1::QuobyteVolumeSource;
  use Moose;

  has 'group' => (is => 'ro', isa => 'Str'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'registry' => (is => 'ro', isa => 'Str'  );
  has 'user' => (is => 'ro', isa => 'Str'  );
  has 'volume' => (is => 'ro', isa => 'Str'  );
1;
