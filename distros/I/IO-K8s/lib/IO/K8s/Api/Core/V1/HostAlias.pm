package IO::K8s::Api::Core::V1::HostAlias;
  use Moose;
  use IO::K8s;

  has 'hostnames' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'ip' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
