package IO::K8s::Api::Core::V1::ContainerImage;
  use Moose;

  has 'names' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'sizeBytes' => (is => 'ro', isa => 'Int'  );
1;
