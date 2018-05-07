package IO::K8s::Api::Core::V1::ConfigMapVolumeSource;
  use Moose;

  has 'defaultMode' => (is => 'ro', isa => 'Int'  );
  has 'items' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::KeyToPath]'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'optional' => (is => 'ro', isa => 'Bool'  );
1;
