package IO::K8s::Api::Core::V1::Capabilities;
  use Moose;
  use IO::K8s;

  has 'add' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'drop' => (is => 'ro', isa => 'ArrayRef[Str]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
