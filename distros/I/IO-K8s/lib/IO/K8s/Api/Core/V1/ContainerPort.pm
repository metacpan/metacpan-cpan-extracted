package IO::K8s::Api::Core::V1::ContainerPort;
  use Moose;
  use IO::K8s;

  has 'containerPort' => (is => 'ro', isa => 'Int'  );
  has 'hostIP' => (is => 'ro', isa => 'Str'  );
  has 'hostPort' => (is => 'ro', isa => 'Int'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'protocol' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
