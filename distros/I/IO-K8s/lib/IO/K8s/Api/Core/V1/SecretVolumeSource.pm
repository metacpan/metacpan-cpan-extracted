package IO::K8s::Api::Core::V1::SecretVolumeSource;
  use Moose;

  has 'defaultMode' => (is => 'ro', isa => 'Int'  );
  has 'items' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::KeyToPath]'  );
  has 'optional' => (is => 'ro', isa => 'Bool'  );
  has 'secretName' => (is => 'ro', isa => 'Str'  );
1;
