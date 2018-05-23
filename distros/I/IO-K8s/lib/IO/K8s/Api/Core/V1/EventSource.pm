package IO::K8s::Api::Core::V1::EventSource;
  use Moose;
  use IO::K8s;

  has 'component' => (is => 'ro', isa => 'Str'  );
  has 'host' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
