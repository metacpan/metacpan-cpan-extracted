package IO::K8s::Api::Core::V1::SELinuxOptions;
  use Moose;
  use IO::K8s;

  has 'level' => (is => 'ro', isa => 'Str'  );
  has 'role' => (is => 'ro', isa => 'Str'  );
  has 'type' => (is => 'ro', isa => 'Str'  );
  has 'user' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
