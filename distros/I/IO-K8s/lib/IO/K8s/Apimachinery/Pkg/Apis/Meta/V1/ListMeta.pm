package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ListMeta;
  use Moose;
  use IO::K8s;

  has 'continue' => (is => 'ro', isa => 'Str'  );
  has 'resourceVersion' => (is => 'ro', isa => 'Str'  );
  has 'selfLink' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
