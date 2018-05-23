package IO::K8s::Api::Policy::V1beta1::AllowedFlexVolume;
  use Moose;
  use IO::K8s;

  has 'driver' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
