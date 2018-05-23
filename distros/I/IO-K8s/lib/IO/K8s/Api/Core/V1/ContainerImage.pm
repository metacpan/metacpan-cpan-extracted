package IO::K8s::Api::Core::V1::ContainerImage;
  use Moose;
  use IO::K8s;

  has 'names' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'sizeBytes' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
