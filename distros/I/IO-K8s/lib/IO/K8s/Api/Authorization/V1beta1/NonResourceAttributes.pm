package IO::K8s::Api::Authorization::V1beta1::NonResourceAttributes;
  use Moose;
  use IO::K8s;

  has 'path' => (is => 'ro', isa => 'Str'  );
  has 'verb' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
