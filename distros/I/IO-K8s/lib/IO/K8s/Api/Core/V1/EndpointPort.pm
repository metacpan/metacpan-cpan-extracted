package IO::K8s::Api::Core::V1::EndpointPort;
  use Moose;
  use IO::K8s;

  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'port' => (is => 'ro', isa => 'Int'  );
  has 'protocol' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
