package IO::K8s::Api::Extensions::V1beta1::AllowedHostPath;
  use Moose;
  use IO::K8s;

  has 'pathPrefix' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
