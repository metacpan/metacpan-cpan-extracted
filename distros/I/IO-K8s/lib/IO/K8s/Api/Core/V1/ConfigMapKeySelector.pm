package IO::K8s::Api::Core::V1::ConfigMapKeySelector;
  use Moose;
  use IO::K8s;

  has 'key' => (is => 'ro', isa => 'Str'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'optional' => (is => 'ro', isa => 'Bool'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
