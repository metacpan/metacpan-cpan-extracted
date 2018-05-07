package IO::K8s::Api::Core::V1::ConfigMapProjection;
  use Moose;

  has 'items' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::KeyToPath]'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'optional' => (is => 'ro', isa => 'Bool'  );
1;
