package IO::K8s::Api::Core::V1::ResourceFieldSelector;
  use Moose;
  use IO::K8s;

  has 'containerName' => (is => 'ro', isa => 'Str'  );
  has 'divisor' => (is => 'ro', isa => 'Str'  );
  has 'resource' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
