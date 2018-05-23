package IO::K8s::Api::Core::V1::ExecAction;
  use Moose;
  use IO::K8s;

  has 'command' => (is => 'ro', isa => 'ArrayRef[Str]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
