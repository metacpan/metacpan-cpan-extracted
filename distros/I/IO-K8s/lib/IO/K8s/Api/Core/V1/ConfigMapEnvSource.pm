package IO::K8s::Api::Core::V1::ConfigMapEnvSource;
  use Moose;
  use IO::K8s;

  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'optional' => (is => 'ro', isa => 'Bool'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
