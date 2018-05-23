package IO::K8s::Api::Core::V1::LimitRangeSpec;
  use Moose;
  use IO::K8s;

  has 'limits' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::LimitRangeItem]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
