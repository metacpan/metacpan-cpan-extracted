package IO::K8s::Api::Core::V1::NodeAddress;
  use Moose;
  use IO::K8s;

  has 'address' => (is => 'ro', isa => 'Str'  );
  has 'type' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
