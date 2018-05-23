package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Initializer;
  use Moose;
  use IO::K8s;

  has 'name' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
