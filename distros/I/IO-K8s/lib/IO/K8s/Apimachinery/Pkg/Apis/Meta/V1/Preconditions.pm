package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Preconditions;
  use Moose;
  use IO::K8s;

  has 'uid' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
