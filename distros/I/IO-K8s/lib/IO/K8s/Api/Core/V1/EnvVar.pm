package IO::K8s::Api::Core::V1::EnvVar;
  use Moose;
  use IO::K8s;

  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'value' => (is => 'ro', isa => 'Str'  );
  has 'valueFrom' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::EnvVarSource'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
