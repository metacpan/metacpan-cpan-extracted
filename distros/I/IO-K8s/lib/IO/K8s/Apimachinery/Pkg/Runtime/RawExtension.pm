package IO::K8s::Apimachinery::Pkg::Runtime::RawExtension;
  use Moose;
  use IO::K8s;

  has 'Raw' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
